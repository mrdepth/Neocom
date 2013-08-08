//
//  ModulesDataSource.m
//  EVEUniverse
//
//  Created by mr_depth on 02.08.13.
//
//

#import "ModulesDataSource.h"
#import "EUOperationQueue.h"
#import "FittingViewController.h"
#import "NSString+Fitting.h"
#import "NSString+TimeLeft.h"
#import "ModuleCellView.h"
#import "UITableViewCell+Nib.h"
#import "NSNumberFormatter+Neocom.h"
#import "UIActionSheet+Block.h"
#import "UIActionSheet+Neocom.h"
#import "FittingVariationsViewController.h"
#import "ItemViewController.h"

#define ActionButtonOffline NSLocalizedString(@"Put Offline", nil)
#define ActionButtonOnline NSLocalizedString(@"Put Online", nil)
#define ActionButtonOverheatOn NSLocalizedString(@"Enable Overheating", nil)
#define ActionButtonOverheatOff NSLocalizedString(@"Disable Overheating", nil)
#define ActionButtonActivate NSLocalizedString(@"Activate", nil)
#define ActionButtonDeactivate NSLocalizedString(@"Deactivate", nil)
#define ActionButtonAmmo NSLocalizedString(@"Ammo", nil)
#define ActionButtonCancel NSLocalizedString(@"Cancel", nil)
#define ActionButtonDelete NSLocalizedString(@"Delete", nil)
#define ActionButtonChangeState NSLocalizedString(@"Change State", nil)
#define ActionButtonUnloadAmmo NSLocalizedString(@"Unload Ammo", nil)
#define ActionButtonShowModuleInfo NSLocalizedString(@"Show Module Info", nil)
#define ActionButtonShowAmmoInfo NSLocalizedString(@"Show Ammo Info", nil)
#define ActionButtonSetTarget NSLocalizedString(@"Set Target", nil)
#define ActionButtonClearTarget NSLocalizedString(@"Clear Target", nil)
#define ActionButtonVariations NSLocalizedString(@"Variations", nil)
#define ActionButtonAllSimilarModules NSLocalizedString(@"All Similar Modules", nil)

@interface ModulesDataSource()
@property (nonatomic, strong) NSArray* sections;
- (void) performActionForRowAtIndexPath:(NSIndexPath*) indexPath;
@end

@implementation ModulesDataSource

- (void) reload {
	__block float totalPG;
	__block float usedPG;
	__block float totalCPU;
	__block float usedCPU;
	__block float totalCalibration;
	__block float usedCalibration;
	__block int usedTurretHardpoints;
	__block int totalTurretHardpoints;
	__block int usedMissileHardpoints;
	__block int totalMissileHardpoints;
	
	NSMutableArray *sectionsTmp = [NSMutableArray array];
	
	__block EUOperation *operation = [EUOperation operationWithIdentifier:@"ModulesDataSource+reload" name:NSLocalizedString(@"Updating Modules", nil)];
	__weak EUOperation* weakOperation = operation;
	[operation addExecutionBlock:^(void) {
		@synchronized(self.fittingViewController) {
			eufe::Ship* ship = self.fittingViewController.fit.character->getShip();
			
			eufe::Module::Slot slots[] = {eufe::Module::SLOT_HI, eufe::Module::SLOT_MED, eufe::Module::SLOT_LOW, eufe::Module::SLOT_RIG, eufe::Module::SLOT_SUBSYSTEM};
			int n = sizeof(slots) / sizeof(eufe::Module::Slot);
			
			for (int i = 0; i < n; i++)
			{
				weakOperation.progress = (float) i / (float) n;
				int numberOfSlots = ship->getNumberOfSlots(slots[i]);
				if (numberOfSlots > 0)
				{
					eufe::ModulesList modules;
					ship->getModules(slots[i], std::inserter(modules, modules.end()));
					eufe::ModulesList::iterator j, endj = modules.end();
					NSMutableArray* array = [NSMutableArray array];
					for (j = modules.begin(); j != endj; j++)
						[array addObject:[ItemInfo itemInfoWithItem:*j error:nil]];
					[sectionsTmp addObject:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:(int) slots[i]], @"slot",
											[NSNumber numberWithInt:numberOfSlots], @"count",
											array, @"modules", nil]];
				}
			}
			
			totalPG = ship->getTotalPowerGrid();
			usedPG = ship->getPowerGridUsed();
			
			totalCPU = ship->getTotalCpu();
			usedCPU = ship->getCpuUsed();
			
			totalCalibration = ship->getTotalCalibration();
			usedCalibration = ship->getCalibrationUsed();
			
			usedTurretHardpoints = ship->getUsedHardpoints(eufe::Module::HARDPOINT_TURRET);
			totalTurretHardpoints = ship->getNumberOfHardpoints(eufe::Module::HARDPOINT_TURRET);
			usedMissileHardpoints = ship->getUsedHardpoints(eufe::Module::HARDPOINT_LAUNCHER);
			totalMissileHardpoints = ship->getNumberOfHardpoints(eufe::Module::HARDPOINT_LAUNCHER);
		}
	}];
	
	[operation setCompletionBlockInMainThread:^(void) {
		if (![weakOperation isCancelled]) {
			self.sections = sectionsTmp;
			
			self.powerGridLabel.text = [NSString stringWithTotalResources:totalPG usedResources:usedPG unit:@"MW"];
			self.powerGridLabel.progress = totalPG > 0 ? usedPG / totalPG : 0;
			self.cpuLabel.text = [NSString stringWithTotalResources:totalCPU usedResources:usedCPU unit:@"tf"];
			self.cpuLabel.progress = usedCPU > 0 ? usedCPU / totalCPU : 0;
			self.calibrationLabel.text = [NSString stringWithFormat:@"%d/%d", (int) usedCalibration, (int) totalCalibration];
			self.calibrationLabel.progress = totalCalibration > 0 ? usedCalibration / totalCalibration : 0;
			self.turretsLabel.text = [NSString stringWithFormat:@"%d/%d", usedTurretHardpoints, totalTurretHardpoints];
			self.launchersLabel.text = [NSString stringWithFormat:@"%d/%d", usedMissileHardpoints, totalMissileHardpoints];
			
			if (self.tableView.dataSource == self)
				[self.tableView reloadData];
		}
	}];
	
	[[EUOperationQueue sharedQueue] addOperation:operation];
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.sections.count;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return [self.sections[section][@"count"] integerValue];
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
	NSArray *modules = self.sections[indexPath.section][@"modules"];
	if (indexPath.row >= modules.count) {
		NSString *cellIdentifier = @"ModuleCellView";
		ModuleCellView *cell = (ModuleCellView*) [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
		if (cell == nil) {
			cell = [ModuleCellView cellWithNibName:@"ModuleCellView" bundle:nil reuseIdentifier:cellIdentifier];
		}
		cell.stateView.image = nil;
		cell.targetView.image = nil;
		eufe::Module::Slot slot = static_cast<eufe::Module::Slot>([[[self.sections objectAtIndex:indexPath.section] valueForKey:@"slot"] integerValue]);
		switch (slot) {
			case eufe::Module::SLOT_HI:
				cell.iconView.image = [UIImage imageNamed:@"slotHigh.png"];
				cell.titleLabel.text = NSLocalizedString(@"High slot", nil);
				break;
			case eufe::Module::SLOT_MED:
				cell.iconView.image = [UIImage imageNamed:@"slotMed.png"];
				cell.titleLabel.text = NSLocalizedString(@"Med slot", nil);
				break;
			case eufe::Module::SLOT_LOW:
				cell.iconView.image = [UIImage imageNamed:@"slotLow.png"];
				cell.titleLabel.text = NSLocalizedString(@"Low slot", nil);
				break;
			case eufe::Module::SLOT_RIG:
				cell.iconView.image = [UIImage imageNamed:@"slotRig.png"];
				cell.titleLabel.text = NSLocalizedString(@"Rig slot", nil);
				break;
			case eufe::Module::SLOT_SUBSYSTEM:
				cell.iconView.image = [UIImage imageNamed:@"slotSubsystem.png"];
				cell.titleLabel.text = NSLocalizedString(@"Subsystem slot", nil);
				break;
			default:
				cell.iconView.image = nil;
				cell.titleLabel.text = nil;
		}
		
		int groupStyle = 0;
		if (indexPath.row == 0)
			groupStyle |= GroupedCellGroupStyleTop;
		if (indexPath.row == [self tableView:tableView numberOfRowsInSection:indexPath.section] - 1)
			groupStyle |= GroupedCellGroupStyleBottom;
		cell.groupStyle = static_cast<GroupedCellGroupStyle>(groupStyle);
		return cell;
	}
	else {
		ItemInfo* itemInfo = modules[indexPath.row];
		eufe::Module* module = dynamic_cast<eufe::Module*>(itemInfo.item);
		eufe::Charge* charge = module->getCharge();
		
		
		bool useCharge = charge != NULL;
		int optimal = (int) module->getMaxRange();
		int falloff = (int) module->getFalloff();
		float trackingSpeed = module->getTrackingSpeed();
		float lifeTime = module->getLifeTime();
		
		NSString *cellIdentifier;
		int additionalRows = 0;
		if (useCharge) {
			if (optimal > 0)
				additionalRows = 2;
			else
				additionalRows = 1;
		}
		else {
			if (optimal > 0)
				additionalRows = 1;
			else
				additionalRows = 0;
		}
		
		if (lifeTime > 0)
			additionalRows++;
		
		if (additionalRows > 0)
			cellIdentifier = [NSString stringWithFormat:@"ModuleCellView%d", additionalRows];
		else
			cellIdentifier = @"ModuleCellView";
		
		ModuleCellView *cell = (ModuleCellView*) [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
		if (cell == nil) {
			cell = [ModuleCellView cellWithNibName:@"ModuleCellView" bundle:nil reuseIdentifier:cellIdentifier];
		}
		
		cell.titleLabel.text = itemInfo.typeName;
		if (charge != NULL)
		{
			ItemInfo* chargeInfo = [ItemInfo itemInfoWithItem: charge error:nil];
			cell.row1Label.text = chargeInfo.typeName;
		}
		
		if (optimal > 0) {
			NSString *s = [NSString stringWithFormat:NSLocalizedString(@"%@m", nil), [NSNumberFormatter neocomLocalizedStringFromNumber:@(optimal)]];
			if (falloff > 0)
				s = [s stringByAppendingFormat:NSLocalizedString(@" + %@m", nil), [NSNumberFormatter neocomLocalizedStringFromNumber:@(falloff)]];
			if (trackingSpeed > 0)
				s = [s stringByAppendingFormat:NSLocalizedString(@" (%@ rad/sec)", nil), [NSNumberFormatter neocomLocalizedStringFromNumber:@(trackingSpeed)]];
			if (charge != NULL)
				cell.row2Label.text = s;
			else
				cell.row1Label.text = s;
		}
		
		cell.iconView.image = [UIImage imageNamed:[itemInfo typeSmallImageName]];
		eufe::Module::Slot slot = module->getSlot();
		if (slot == eufe::Module::SLOT_HI || slot == eufe::Module::SLOT_MED || slot == eufe::Module::SLOT_LOW) {
			switch (module->getState()) {
				case eufe::Module::STATE_ACTIVE:
					cell.stateView.image = [UIImage imageNamed:@"active.png"];
					break;
				case eufe::Module::STATE_ONLINE:
					cell.stateView.image = [UIImage imageNamed:@"online.png"];
					break;
				case eufe::Module::STATE_OVERLOADED:
					cell.stateView.image = [UIImage imageNamed:@"overheated.png"];
					break;
				default:
					cell.stateView.image = [UIImage imageNamed:@"offline.png"];
					break;
			}
		}
		else
			cell.stateView.image = nil;
		
		if (lifeTime > 0) {
			NSString* s = [NSString stringWithFormat:NSLocalizedString(@"Lifetime: %@", nil), [NSString stringWithTimeLeft:lifeTime]];
			if (additionalRows == 1)
				cell.row1Label.text = s;
			else if (additionalRows == 2)
				cell.row2Label.text = s;
			else if (additionalRows == 3)
				cell.row3Label.text = s;
		}
		
		cell.targetView.image = module->getTarget() != NULL ? [UIImage imageNamed:@"Icons/icon04_12.png"] : nil;
		
		int groupStyle = 0;
		if (indexPath.row == 0)
			groupStyle |= GroupedCellGroupStyleTop;
		if (indexPath.row == [self tableView:tableView numberOfRowsInSection:indexPath.section] - 1)
			groupStyle |= GroupedCellGroupStyleBottom;
		cell.groupStyle = static_cast<GroupedCellGroupStyle>(groupStyle);
		return cell;
	}
}

#pragma mark -
#pragma mark Table view delegate

- (CGFloat)tableView:(UITableView *)aTableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return [[self tableView:aTableView cellForRowAtIndexPath:indexPath] frame].size.height;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
	switch ((eufe::Module::Slot)[[[self.sections objectAtIndex:section] valueForKey:@"slot"] integerValue]) {
		case eufe::Module::SLOT_HI:
			return self.highSlotsHeaderView;
		case eufe::Module::SLOT_MED:
			return self.medSlotsHeaderView;
		case eufe::Module::SLOT_LOW:
			return self.lowSlotsHeaderView;
		case eufe::Module::SLOT_RIG:
			return self.rigsSlotsHeaderView;
		case eufe::Module::SLOT_SUBSYSTEM:
			return self.subsystemsSlotsHeaderView;
		default:
			break;
	}
	return nil;
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
	return 25;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	NSArray *modules = self.sections[indexPath.section][@"modules"];
	eufe::Character* character = self.fittingViewController.fit.character;
	eufe::Ship* ship = character->getShip();
	if (indexPath.row >= modules.count) {
		switch ((eufe::Module::Slot)[[[self.sections objectAtIndex:indexPath.section] valueForKey:@"slot"] integerValue]) {
			case eufe::Module::SLOT_HI:
				self.fittingViewController.itemsViewController.conditions = @[@"dgmTypeEffects.typeID = invTypes.typeID", @"dgmTypeEffects.effectID = 12"];
				self.fittingViewController.itemsViewController.title = NSLocalizedString(@"Hi slot", nil);
				break;
			case eufe::Module::SLOT_MED:
				self.fittingViewController.itemsViewController.conditions = @[@"dgmTypeEffects.typeID = invTypes.typeID", @"dgmTypeEffects.effectID = 13"];
				self.fittingViewController.itemsViewController.title = NSLocalizedString(@"Med slot", nil);
				break;
			case eufe::Module::SLOT_LOW:
				self.fittingViewController.itemsViewController.conditions = @[@"dgmTypeEffects.typeID = invTypes.typeID", @"dgmTypeEffects.effectID = 11"];
				self.fittingViewController.itemsViewController.title = NSLocalizedString(@"Low slot", nil);
				//self.fittingViewController.fittingItemsViewController.title = NSLocalizedString(@"Ship Equipment", nil);
				break;
			case eufe::Module::SLOT_RIG:
				self.fittingViewController.itemsViewController.conditions = @[@"dgmTypeEffects.typeID = invTypes.typeID",
																  @"dgmTypeEffects.effectID = 2663",
																  @"dgmTypeAttributes.typeID = invTypes.typeID",
																  @"dgmTypeAttributes.attributeID = 1547",
																  [NSString stringWithFormat:@"dgmTypeAttributes.value = %d", static_cast<int>(ship->getAttribute(1547)->getValue())]];
				self.fittingViewController.itemsViewController.title = NSLocalizedString(@"Rigs", nil);
				break;
			case eufe::Module::SLOT_SUBSYSTEM: {
				NSInteger raceID = static_cast<NSInteger>(ship->getAttribute(eufe::RACE_ID_ATTRIBUTE_ID)->getValue());
				switch(raceID) {
					case 1: //Caldari
						self.fittingViewController.itemsViewController.title = NSLocalizedString(@"Caldari Subsystems", nil);
						break;
					case 2: //Minmatar
						self.fittingViewController.itemsViewController.title = NSLocalizedString(@"Minmatar Subsystems", nil);
						break;
					case 4: //Amarr
						self.fittingViewController.itemsViewController.title = NSLocalizedString(@"Amarr Subsystems", nil);
						break;
					case 8: //Gallente
						self.fittingViewController.itemsViewController.title = NSLocalizedString(@"Gallente Subsystems", nil);
						break;
				}
				self.fittingViewController.itemsViewController.conditions = @[@"dgmTypeEffects.typeID = invTypes.typeID",
																  @"dgmTypeEffects.effectID = 3772",
																  [NSString stringWithFormat:@"invTypes.raceID=%d", raceID]];
				break;
			}
			default:
				return;
				
		}
		
		
		self.fittingViewController.itemsViewController.completionHandler = ^(EVEDBInvType* type) {
			ship->addModule(type.typeID);
			[self.fittingViewController update];
		};
		
		[self.fittingViewController presentViewController:self.fittingViewController.itemsViewController animated:YES completion:nil];
		
#warning todo
//		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
//			[popoverController presentPopoverFromRect:[self.tableView rectForRowAtIndexPath:indexPath] inView:self.tableView permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
//		else
//			[self.fittingViewController presentModalViewController:self.fittingItemsViewController.navigationController animated:YES];
	}
	else {
		[self performActionForRowAtIndexPath:indexPath];
	}
}

#pragma mark - Private

- (void) performActionForRowAtIndexPath:(NSIndexPath*) indexPath {
	NSArray *modules = self.sections[indexPath.section][@"modules"];

	eufe::Ship* ship = self.fittingViewController.fit.character->getShip();
	ItemInfo* itemInfo = [modules objectAtIndex:indexPath.row];
	eufe::Module* module = dynamic_cast<eufe::Module*>(itemInfo.item);
	
	NSMutableArray* allSimilarModules = [NSMutableArray new];
	bool multiple = false;
	for (ItemInfo* item in modules) {
		if (item.marketGroupID == itemInfo.marketGroupID) {
			[allSimilarModules addObject:item];
		}
	}
	multiple = allSimilarModules.count > 1;
	

	eufe::Module::State state = module->getState();
	
	void (^remove)(NSArray*) = ^(NSArray* modules){
		for (ItemInfo* itemInfo in modules) {
			eufe::Module* module = dynamic_cast<eufe::Module*>(itemInfo.item);
			self.fittingViewController.fit.character->getShip()->removeModule(module);
		}
		[self.fittingViewController update];
	};

	void (^putOffline)(NSArray*) = ^(NSArray* modules){
		for (ItemInfo* itemInfo in modules) {
			eufe::Module* module = dynamic_cast<eufe::Module*>(itemInfo.item);
			module->setState(eufe::Module::STATE_OFFLINE);
		}
		[self.fittingViewController update];
	};
	void (^putOnline)(NSArray*) = ^(NSArray* modules){
		for (ItemInfo* itemInfo in modules) {
			eufe::Module* module = dynamic_cast<eufe::Module*>(itemInfo.item);
			if (module->canHaveState(eufe::Module::STATE_ACTIVE))
				module->setState(eufe::Module::STATE_ACTIVE);
			else
				module->setState(eufe::Module::STATE_ONLINE);
		}
		[self.fittingViewController update];
	};
	void (^activate)(NSArray*) = ^(NSArray* modules){
		for (ItemInfo* itemInfo in modules) {
			eufe::Module* module = dynamic_cast<eufe::Module*>(itemInfo.item);
			module->setState(eufe::Module::STATE_ACTIVE);
		}
		[self.fittingViewController update];
	};
	void (^deactivate)(NSArray*) = ^(NSArray* modules){
		for (ItemInfo* itemInfo in modules) {
			eufe::Module* module = dynamic_cast<eufe::Module*>(itemInfo.item);
			module->setState(eufe::Module::STATE_ONLINE);
		}
		[self.fittingViewController update];
	};
	void (^enableOverheating)(NSArray*) = ^(NSArray* modules){
		for (ItemInfo* itemInfo in modules) {
			eufe::Module* module = dynamic_cast<eufe::Module*>(itemInfo.item);
			module->setState(eufe::Module::STATE_OVERLOADED);
		}
		[self.fittingViewController update];
	};
	void (^disableOverheating)(NSArray*) = ^(NSArray* modules){
		for (ItemInfo* itemInfo in modules) {
			eufe::Module* module = dynamic_cast<eufe::Module*>(itemInfo.item);
			module->setState(eufe::Module::STATE_ACTIVE);
		}
		[self.fittingViewController update];
	};

	NSMutableArray* statesButtons = [NSMutableArray new];
	NSMutableArray* statesActions = [NSMutableArray new];
	
	if (state >= eufe::Module::STATE_ACTIVE) {
		[statesButtons addObject:ActionButtonOffline];
		[statesActions addObject:putOffline];
		
		[statesButtons addObject:ActionButtonDeactivate];
		[statesActions addObject:deactivate];
		
		if (module->canHaveState(eufe::Module::STATE_OVERLOADED)) {
			if (state == eufe::Module::STATE_OVERLOADED) {
				[statesButtons addObject:ActionButtonOverheatOff];
				[statesActions addObject:disableOverheating];
			}
			else {
				[statesButtons addObject:ActionButtonOverheatOn];
				[statesActions addObject:enableOverheating];
			}
		}
	}
	else if (state == eufe::Module::STATE_ONLINE) {
		[statesButtons addObject:ActionButtonOffline];
		[statesActions addObject:putOffline];
		if (module->canHaveState(eufe::Module::STATE_ACTIVE)) {
			[statesButtons addObject:ActionButtonActivate];
			[statesActions addObject:activate];
		}
	}
	else {
		[statesButtons addObject:ActionButtonOnline];
		[statesActions addObject:putOnline];
	}
	
	void (^setAmmo)(NSArray*) = ^(NSArray* modules){
		const std::vector<eufe::TypeID>& chargeGroups = module->getChargeGroups();
		std::vector<eufe::TypeID>::const_iterator i, end = chargeGroups.end();
		int chargeSize = module->getChargeSize();
		
		NSMutableArray *groups = [NSMutableArray new];
		for (i = chargeGroups.begin(); i != end; i++)
			[groups addObject:[NSString stringWithFormat:@"%d", *i]];
		
		self.fittingViewController.itemsViewController.title = NSLocalizedString(@"Ammo", nil);
		if (chargeSize)
			self.fittingViewController.itemsViewController.conditions = @[@"invTypes.typeID=dgmTypeAttributes.typeID",
																 @"dgmTypeAttributes.attributeID=128",
																 [NSString stringWithFormat:@"dgmTypeAttributes.value=%d", chargeSize],
																 [NSString stringWithFormat:@"groupID IN (%@)", [groups componentsJoinedByString:@","]]];
		else
			self.fittingViewController.itemsViewController.conditions = @[[NSString stringWithFormat:@"groupID IN (%@)", [groups componentsJoinedByString:@","]],
																 [NSString stringWithFormat:@"invTypes.volume <= %f", module->getAttribute(eufe::CAPACITY_ATTRIBUTE_ID)->getValue()]];
		
		self.fittingViewController.itemsViewController.completionHandler = ^(EVEDBInvType* type) {
			for (ItemInfo* itemInfo in modules) {
				eufe::Module* module = dynamic_cast<eufe::Module*>(itemInfo.item);
				module->setCharge(type.typeID);
			}
			[self.fittingViewController update];
		};
		
		[self.fittingViewController presentViewController:self.fittingViewController.itemsViewController animated:YES completion:nil];
	};
	void (^unloadAmmo)(NSArray*) = ^(NSArray* modules){
		for (ItemInfo* itemInfo in modules) {
			eufe::Module* module = dynamic_cast<eufe::Module*>(itemInfo.item);
			module->clearCharge();
		}
		[self.fittingViewController update];
	};

	void (^changeState)(NSArray*) = ^(NSArray* modules){
		[[UIActionSheet actionSheetWithStyle:UIActionSheetStyleBlackOpaque
									   title:nil
						   cancelButtonTitle:NSLocalizedString(@"Cancel", )
					  destructiveButtonTitle:nil
						   otherButtonTitles:statesButtons
							 completionBlock:^(UIActionSheet *actionSheet, NSInteger selectedButtonIndex) {
								 if (selectedButtonIndex != actionSheet.cancelButtonIndex) {
									 void (^block)(NSArray*) = statesActions[selectedButtonIndex];
									 block(@[itemInfo]);
								 }
							 } cancelBlock:nil] showInWindowFromRect:[self.tableView rectForRowAtIndexPath:indexPath] inView:self.tableView animated:YES];
	};

	void (^moduleInfo)(NSArray*) = ^(NSArray* modules){
		ItemViewController *itemViewController = [[ItemViewController alloc] initWithNibName:@"ItemViewController" bundle:nil];
		[itemInfo updateAttributes];
		itemViewController.type = itemInfo;
		[itemViewController setActivePage:ItemViewControllerActivePageInfo];
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
			UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:itemViewController];
			navController.modalPresentationStyle = UIModalPresentationFormSheet;
			[self.fittingViewController presentModalViewController:navController animated:YES];
		}
		else
			[self.fittingViewController.navigationController pushViewController:itemViewController animated:YES];
	};
	void (^ammoInfo)(NSArray*) = ^(NSArray* modules){
		ItemViewController *itemViewController = [[ItemViewController alloc] initWithNibName:@"ItemViewController" bundle:nil];
		ItemInfo* ammo = [ItemInfo itemInfoWithItem:module->getCharge() error:nil];
		[ammo updateAttributes];
		itemViewController.type = ammo;
		[itemViewController setActivePage:ItemViewControllerActivePageInfo];
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
			UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:itemViewController];
			navController.modalPresentationStyle = UIModalPresentationFormSheet;
			[self.fittingViewController presentModalViewController:navController animated:YES];
		}
		else
			[self.fittingViewController.navigationController pushViewController:itemViewController animated:YES];
	};

	void (^setTarget)(NSArray*) = ^(NSArray* modules){
	};
	void (^clearTarget)(NSArray*) = ^(NSArray* modules){
	};

	void (^variations)(NSArray*) = ^(NSArray* modules){
		FittingVariationsViewController* controller = [[FittingVariationsViewController alloc] initWithNibName:@"VariationsViewController" bundle:nil];
		controller.type = itemInfo;

		controller.completionHandler = ^(EVEDBInvType* type) {
			for (ItemInfo* itemInfo in modules) {
				eufe::Module* module = dynamic_cast<eufe::Module*>(itemInfo.item);
				ship->replaceModule(module, type.typeID);
			}
			[self.fittingViewController update];
		};
		
		UINavigationController* navigationController = [[UINavigationController alloc] initWithRootViewController:controller];
		[self.fittingViewController presentViewController:navigationController animated:YES completion:nil];
	};

	void (^similarModules)(NSArray*) = ^(NSArray* modules){
		NSMutableArray* buttons = [NSMutableArray new];
		NSMutableArray* actions = [NSMutableArray new];

		[actions addObject:remove];
		[buttons addObjectsFromArray:statesButtons];
		[actions addObjectsFromArray:statesActions];
		
		if (module->getChargeGroups().size() > 0) {
			[buttons addObject:ActionButtonAmmo];
			[actions addObject:setAmmo];
			
			if (module->getCharge() != nil) {
				[buttons addObject:ActionButtonUnloadAmmo];
				[actions addObject:unloadAmmo];
			}
		}
		[buttons addObject:ActionButtonVariations];
		[actions addObject:variations];
		
		[[UIActionSheet actionSheetWithStyle:UIActionSheetStyleBlackOpaque
									   title:nil
						   cancelButtonTitle:NSLocalizedString(@"Cancel", )
					  destructiveButtonTitle:ActionButtonDelete
						   otherButtonTitles:buttons
							 completionBlock:^(UIActionSheet *actionSheet, NSInteger selectedButtonIndex) {
								 if (selectedButtonIndex != actionSheet.cancelButtonIndex) {
									 void (^block)(NSArray*) = actions[selectedButtonIndex];
									 block(allSimilarModules);
								 }
							 } cancelBlock:nil] showInWindowFromRect:[self.tableView rectForRowAtIndexPath:indexPath] inView:self.tableView animated:YES];
	};

	NSMutableArray* buttons = [NSMutableArray new];
	NSMutableArray* actions = [NSMutableArray new];
	
	[actions addObject:remove];
	
	[buttons addObject:ActionButtonShowModuleInfo];
	[actions addObject:moduleInfo];
	if (module->getCharge() != NULL) {
		[buttons addObject:ActionButtonShowAmmoInfo];
		[actions addObject:ammoInfo];
	}
	

	
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		[buttons addObjectsFromArray:statesButtons];
		[actions addObjectsFromArray:statesActions];
	}
	else {
		[buttons addObject:ActionButtonChangeState];
		[actions addObject:changeState];
	}
	
	if (module->getChargeGroups().size() > 0) {
		[buttons addObject:ActionButtonAmmo];
		[actions addObject:setAmmo];

		if (module->getCharge() != nil) {
			[buttons addObject:ActionButtonUnloadAmmo];
			[actions addObject:unloadAmmo];
		}
	}
	if (module->requireTarget() && self.fittingViewController.fits.count > 1) {
		[buttons addObject:ActionButtonSetTarget];
		[actions addObject:setTarget];
		if (module->getTarget() != NULL) {
			[buttons addObject:ActionButtonClearTarget];
			[actions addObject:clearTarget];
		}
	}
	[buttons addObject:ActionButtonVariations];
	[actions addObject:variations];
	
	if (multiple) {
		[buttons addObject:ActionButtonAllSimilarModules];
		[actions addObject:similarModules];
	}
	
	[[UIActionSheet actionSheetWithStyle:UIActionSheetStyleBlackOpaque
								   title:nil
					   cancelButtonTitle:NSLocalizedString(@"Cancel", )
				  destructiveButtonTitle:ActionButtonDelete
					   otherButtonTitles:buttons
						 completionBlock:^(UIActionSheet *actionSheet, NSInteger selectedButtonIndex) {
							 if (selectedButtonIndex != actionSheet.cancelButtonIndex) {
								 void (^block)(NSArray*) = actions[selectedButtonIndex];
								 block(@[itemInfo]);
							 }
						 } cancelBlock:nil] showInWindowFromRect:[self.tableView rectForRowAtIndexPath:indexPath] inView:self.tableView animated:YES];
}

@end
