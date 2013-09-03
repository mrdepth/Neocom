//
//  StructuresDataSource.m
//  EVEUniverse
//
//  Created by mr_depth on 14.08.13.
//
//

#import "StructuresDataSource.h"
#import "POSFittingViewController.h"
#import "EUOperationQueue.h"
#import "eufe.h"
#import "NSString+Fitting.h"
#import "ItemInfo.h"
#import "POSFit.h"

#import "UIActionSheet+Block.h"
#import "UIActionSheet+Neocom.h"
#import "ModuleCellView.h"
#import "UITableViewCell+Nib.h"
#import "ItemViewController.h"
#import "UIViewController+Neocom.h"
#import "AmountViewController.h"

#define ActionButtonOffline NSLocalizedString(@"Put Offline", nil)
#define ActionButtonOnline NSLocalizedString(@"Put Online", nil)
#define ActionButtonActivate NSLocalizedString(@"Activate", nil)
#define ActionButtonDeactivate NSLocalizedString(@"Deactivate", nil)
#define ActionButtonAmmoCurrentModule NSLocalizedString(@"Ammo (Current Module)", nil)
#define ActionButtonAmmoAllModules NSLocalizedString(@"Ammo (All Modules)", nil)
#define ActionButtonAmmo NSLocalizedString(@"Ammo", nil)
#define ActionButtonCancel NSLocalizedString(@"Cancel", nil)
#define ActionButtonDelete NSLocalizedString(@"Delete", nil)
#define ActionButtonChangeState NSLocalizedString(@"Change State", nil)
#define ActionButtonUnloadAmmo NSLocalizedString(@"Unload Ammo", nil)
#define ActionButtonShowModuleInfo NSLocalizedString(@"Show Module Info", nil)
#define ActionButtonShowAmmoInfo NSLocalizedString(@"Show Ammo Info", nil)
#define ActionButtonAmount NSLocalizedString(@"Set Amount", nil)

@interface StructuresDataSource()
@property (nonatomic, strong) NSArray* structures;

@end


@implementation StructuresDataSource

- (void) reload {
	__block float totalPG;
	__block float usedPG;
	__block float totalCPU;
	__block float usedCPU;
	
	NSMutableArray *structuresTmp = [NSMutableArray array];
	
	EUOperation *operation = [EUOperation operationWithIdentifier:@"StructuresDataSource+reload" name:NSLocalizedString(@"Updating POS Structures", nil)];
	__weak EUOperation* weakOperation = operation;
	[operation addExecutionBlock:^(void) {
		@synchronized(self.posFittingViewController) {
			eufe::ControlTower* controlTower = self.posFittingViewController.fit.controlTower;
			
			NSMutableDictionary* structuresDic = [NSMutableDictionary dictionary];
			
			const eufe::StructuresList& structuresList = controlTower->getStructures();
			eufe::StructuresList::const_iterator i, end = structuresList.end();
			float n = structuresList.size();
			float j = 0;
			for (i = structuresList.begin(); i != end; i++) {
				weakOperation.progress = j++ / n;
				NSString* key = [NSString stringWithFormat:@"%d", (*i)->getTypeID()];
				NSMutableArray* array = [structuresDic valueForKey:key];
				if (!array) {
					array = [NSMutableArray array];
					[structuresDic setValue:array forKey:key];
					[structuresTmp addObject:array];
				}
				[array addObject:[ItemInfo itemInfoWithItem:*i error:nil]];
			}
			
			
			totalPG = controlTower->getTotalPowerGrid();
			usedPG = controlTower->getPowerGridUsed();
			
			totalCPU = controlTower->getTotalCpu();
			usedCPU = controlTower->getCpuUsed();
		}
	}];
	
	[operation setCompletionBlockInMainThread:^(void) {
		if (![weakOperation isCancelled]) {
			self.structures  = structuresTmp;
			
			self.powerGridLabel.text = [NSString stringWithTotalResources:totalPG usedResources:usedPG unit:@"MW"];
			self.powerGridLabel.progress = totalPG > 0 ? usedPG / totalPG : 0;
			self.cpuLabel.text = [NSString stringWithTotalResources:totalCPU usedResources:usedCPU unit:@"tf"];
			self.cpuLabel.progress = usedCPU > 0 ? usedCPU / totalCPU : 0;
			if (self.tableView.dataSource == self)
				[self.tableView reloadData];
		}
	}];
	
	[[EUOperationQueue sharedQueue] addOperation:operation];
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return self.structures.count + 1;
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
	if (indexPath.row >= self.structures.count) {
		NSString *cellIdentifier = @"ModuleCellView";
		ModuleCellView *cell = (ModuleCellView*) [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
		if (cell == nil) {
			cell = [ModuleCellView cellWithNibName:@"ModuleCellView" bundle:nil reuseIdentifier:cellIdentifier];
		}
		cell.stateView.image = nil;
		cell.targetView.image = nil;
		cell.iconView.image = [UIImage imageNamed:@"slotRig.png"];
		cell.titleLabel.text = NSLocalizedString(@"Add Structure", nil);
		
		int groupStyle = 0;
		if (indexPath.row == 0)
			groupStyle |= GroupedCellGroupStyleTop;
		if (indexPath.row == [self tableView:tableView numberOfRowsInSection:indexPath.section] - 1)
			groupStyle |= GroupedCellGroupStyleBottom;
		cell.groupStyle = static_cast<GroupedCellGroupStyle>(groupStyle);
		return cell;
	}
	else {
		NSArray* array = [self.structures objectAtIndex:indexPath.row];
		ItemInfo* itemInfo = [array objectAtIndex:0];
		eufe::Structure* structure = dynamic_cast<eufe::Structure*>(itemInfo.item);
		eufe::Charge* charge = structure->getCharge();
		
		
		bool useCharge = charge != NULL;
		int optimal = (int) structure->getMaxRange();
		int falloff = (int) structure->getFalloff();
		float trackingSpeed = structure->getTrackingSpeed();
		
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
		
		if (additionalRows > 0)
			cellIdentifier = [NSString stringWithFormat:@"ModuleCellView%d", additionalRows];
		else
			cellIdentifier = @"ModuleCellView";
		
		ModuleCellView *cell = (ModuleCellView*) [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
		if (cell == nil) {
			cell = [ModuleCellView cellWithNibName:@"ModuleCellView" bundle:nil reuseIdentifier:cellIdentifier];
		}
		
		cell.titleLabel.text = [NSString stringWithFormat:@"%@ (x%d)", itemInfo.typeName, array.count];
		if (charge != NULL)
		{
			ItemInfo* chargeInfo = [ItemInfo itemInfoWithItem:charge error:nil];
			cell.row1Label.text = chargeInfo.typeName;
		}
		
		if (optimal > 0) {
			NSString *s = [NSString stringWithFormat:@"%@m", [NSNumberFormatter localizedStringFromNumber:[NSNumber numberWithInt:optimal] numberStyle:NSNumberFormatterDecimalStyle]];
			if (falloff > 0)
				s = [s stringByAppendingFormat:@" + %@m", [NSNumberFormatter localizedStringFromNumber:[NSNumber numberWithInt:falloff] numberStyle:NSNumberFormatterDecimalStyle]];
			if (trackingSpeed > 0)
				s = [s stringByAppendingFormat:@" (%@ rad/sec)", [NSNumberFormatter localizedStringFromNumber:[NSNumber numberWithFloat:trackingSpeed] numberStyle:NSNumberFormatterDecimalStyle]];
			if (charge != NULL)
				cell.row2Label.text = s;
			else
				cell.row1Label.text = s;
		}
		
		cell.iconView.image = [UIImage imageNamed:[itemInfo typeSmallImageName]];
		switch (structure->getState()) {
			case eufe::Module::STATE_ACTIVE:
				cell.stateView.image = [UIImage imageNamed:@"active.png"];
				break;
			case eufe::Module::STATE_ONLINE:
				cell.stateView.image = [UIImage imageNamed:@"active.png"];
				break;
			default:
				cell.stateView.image = [UIImage imageNamed:@"offline.png"];
				break;
		}
		
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
	if (indexPath.row >= self.structures.count)
		return 40;
	else {
		NSArray* array = [self.structures objectAtIndex:indexPath.row];
		ItemInfo* itemInfo = [array objectAtIndex:0];
		eufe::Structure* structure = dynamic_cast<eufe::Structure*>(itemInfo.item);
		eufe::Charge* charge = structure->getCharge();
		
		bool useCharge = charge != NULL;
		int optimal = (int) structure->getMaxRange();
		
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

		
		static CGFloat sizes[] = {40, 40, 56, 72};
		return sizes[additionalRows];
	}
}

- (void)tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[aTableView deselectRowAtIndexPath:indexPath animated:YES];
	eufe::ControlTower* controlTower = self.posFittingViewController.fit.controlTower;
	if (indexPath.row >= self.structures.count) {
		self.posFittingViewController.itemsViewController.title = NSLocalizedString(@"Structures", nil);

		self.posFittingViewController.itemsViewController.conditions = @[@"invTypes.groupID <> 365",
																   @"invTypes.groupID = invGroups.groupID",
																   @"invGroups.categoryID = 23"];

		
		self.posFittingViewController.itemsViewController.completionHandler = ^(EVEDBInvType* type) {
			controlTower->addStructure(type.typeID);
			[self.posFittingViewController update];
			if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
				[self.posFittingViewController dismiss];
		};
		
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
			[self.posFittingViewController presentViewControllerInPopover:self.posFittingViewController.itemsViewController
															  fromRect:[self.tableView rectForRowAtIndexPath:indexPath]
																inView:self.tableView
											  permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
		else
			[self.posFittingViewController presentViewController:self.posFittingViewController.itemsViewController animated:YES completion:nil];
	}
	else {
		[self performActionForRowAtIndexPath:indexPath];
	}
}



#pragma mark - Private

- (void) performActionForRowAtIndexPath:(NSIndexPath*) indexPath {
	NSArray* array = [self.structures objectAtIndex:indexPath.row];
	ItemInfo* itemInfo = [array objectAtIndex:0];
	eufe::Structure* structure = dynamic_cast<eufe::Structure*>(itemInfo.item);
	eufe::ControlTower* controlTower = self.posFittingViewController.fit.controlTower;

	const std::vector<eufe::TypeID>& chargeGroups = structure->getChargeGroups();
	bool multiple = false;
	int chargeSize = structure->getChargeSize();
	eufe::TypeID typeID = structure->getTypeID();
	if (chargeGroups.size() > 0)
	{
		const eufe::StructuresList& structuresList = controlTower->getStructures();
		eufe::StructuresList::const_iterator i, end = structuresList.end();
		for (i = structuresList.begin(); i != end; i++)
		{
			if ((*i)->getTypeID() != typeID)
			{
				int chargeSize2 = (*i)->getChargeSize();
				if (chargeSize == chargeSize2)
				{
					const std::vector<eufe::TypeID>& chargeGroups2 = (*i)->getChargeGroups();
					std::vector<eufe::TypeID> intersection;
					std::set_intersection(chargeGroups.begin(), chargeGroups.end(), chargeGroups2.begin(), chargeGroups2.end(), std::inserter(intersection, intersection.end()));
					if (intersection.size() > 0)
					{
						multiple = true;
						break;
					}
				}
			}
		}
	}
	
	void (^remove)(NSArray*) = ^(NSArray* structures){
		for (ItemInfo* itemInfo in structures) {
			eufe::Structure* structure = dynamic_cast<eufe::Structure*>(itemInfo.item);
			controlTower->removeStructure(structure);
		}
		[self.posFittingViewController update];
	};
	
	void (^putOffline)(NSArray*) = ^(NSArray* structures){
		for (ItemInfo* itemInfo in structures) {
			eufe::Structure* structure = dynamic_cast<eufe::Structure*>(itemInfo.item);
			structure->setState(eufe::Module::STATE_OFFLINE);
		}
		[self.posFittingViewController update];
	};
	void (^putOnline)(NSArray*) = ^(NSArray* structures){
		for (ItemInfo* itemInfo in structures) {
			eufe::Structure* structure = dynamic_cast<eufe::Structure*>(itemInfo.item);
			structure->setState(eufe::Module::STATE_ACTIVE);
		}
		[self.posFittingViewController update];
	};
	void (^amount)(NSArray*) = ^(NSArray* structures){
		AmountViewController *controller = [[AmountViewController alloc] initWithNibName:@"AmountViewController" bundle:nil];
		controller.amount = array.count;
		controller.maxAmount = 50;
		
		controller.completionHandler = ^(NSInteger amount) {
			int left = array.count - amount;
			if (left < 0) {
				ItemInfo* itemInfo = [array objectAtIndex:0];
				eufe::Structure* structure = dynamic_cast<eufe::Structure*>(itemInfo.item);
				for (;left < 0; left++)
					controlTower->addStructure(new eufe::Structure(*structure))->setCharge(structure->getCharge());
			}
			else if (left > 0) {
				int i = array.count - 1;
				for (; left > 0; left--) {
					ItemInfo* itemInfo = [array objectAtIndex:i--];
					eufe::Structure* structure = dynamic_cast<eufe::Structure*>(itemInfo.item);
					controlTower->removeStructure(structure);
				}
			}
			[self.posFittingViewController update];
			[self.posFittingViewController dismiss];
		};
		
		UINavigationController* navigationController = [[UINavigationController alloc] initWithRootViewController:controller];
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
			[controller presentViewControllerInPopover:self.posFittingViewController
											  fromRect:[self.tableView rectForRowAtIndexPath:indexPath]
												inView:self.tableView
							  permittedArrowDirections:UIPopoverArrowDirectionAny
											  animated:YES];
		else {
			controller.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Close", nil) style:UIBarButtonItemStyleBordered target:self.posFittingViewController action:@selector(dismiss)];
			[self.posFittingViewController presentViewController:navigationController animated:YES completion:nil];
		}
	};

	void (^setAmmo)(NSArray*) = ^(NSArray* structures){
		const std::vector<eufe::TypeID>& chargeGroups = structure->getChargeGroups();
		std::vector<eufe::TypeID>::const_iterator i, end = chargeGroups.end();
		int chargeSize = structure->getChargeSize();
		
		NSMutableArray *groups = [NSMutableArray new];
		for (i = chargeGroups.begin(); i != end; i++)
			[groups addObject:[NSString stringWithFormat:@"%d", *i]];
		
		self.posFittingViewController.itemsViewController.title = NSLocalizedString(@"Ammo", nil);
		if (chargeSize)
			self.posFittingViewController.itemsViewController.conditions = @[@"invTypes.typeID=dgmTypeAttributes.typeID",
																 @"dgmTypeAttributes.attributeID=128",
																 [NSString stringWithFormat:@"dgmTypeAttributes.value=%d", chargeSize],
																 [NSString stringWithFormat:@"groupID IN (%@)", [groups componentsJoinedByString:@","]]];
		else
			self.posFittingViewController.itemsViewController.conditions = @[[NSString stringWithFormat:@"groupID IN (%@)", [groups componentsJoinedByString:@","]],
																 [NSString stringWithFormat:@"invTypes.volume <= %f", structure->getAttribute(eufe::CAPACITY_ATTRIBUTE_ID)->getValue()]];
		
		self.posFittingViewController.itemsViewController.completionHandler = ^(EVEDBInvType* type) {
			for (ItemInfo* itemInfo in structures) {
				eufe::Structure* structure = dynamic_cast<eufe::Structure*>(itemInfo.item);
				structure->setCharge(type.typeID);
			}
			[self.posFittingViewController update];
			[self.posFittingViewController dismiss];
		};
		
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
			[self.posFittingViewController presentViewControllerInPopover:self.posFittingViewController.itemsViewController
																 fromRect:[self.tableView rectForRowAtIndexPath:indexPath]
																   inView:self.tableView
												 permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
		else
			[self.posFittingViewController presentViewController:self.posFittingViewController.itemsViewController animated:YES completion:nil];
	};
	
	void (^setAllModulesAmmo)(NSArray*) = ^(NSArray* structures){
		const std::vector<eufe::TypeID>& chargeGroups = structure->getChargeGroups();
		std::vector<eufe::TypeID>::const_iterator i, end = chargeGroups.end();
		int chargeSize = structure->getChargeSize();
		
		NSMutableArray *groups = [NSMutableArray new];
		for (i = chargeGroups.begin(); i != end; i++)
			[groups addObject:[NSString stringWithFormat:@"%d", *i]];
		
		self.posFittingViewController.itemsViewController.title = NSLocalizedString(@"Ammo", nil);
		if (chargeSize)
			self.posFittingViewController.itemsViewController.conditions = @[@"invTypes.typeID=dgmTypeAttributes.typeID",
																	@"dgmTypeAttributes.attributeID=128",
																	[NSString stringWithFormat:@"dgmTypeAttributes.value=%d", chargeSize],
																	[NSString stringWithFormat:@"groupID IN (%@)", [groups componentsJoinedByString:@","]]];
		else
			self.posFittingViewController.itemsViewController.conditions = @[[NSString stringWithFormat:@"groupID IN (%@)", [groups componentsJoinedByString:@","]],
																	[NSString stringWithFormat:@"invTypes.volume <= %f", structure->getAttribute(eufe::CAPACITY_ATTRIBUTE_ID)->getValue()]];
		
		self.posFittingViewController.itemsViewController.completionHandler = ^(EVEDBInvType* type) {
			eufe::StructuresList::const_iterator i, end = controlTower->getStructures().end();
			for (i = controlTower->getStructures().begin(); i != end; i++) {
				(*i)->setCharge(type.typeID);
			}
			[self.posFittingViewController update];
			[self.posFittingViewController dismiss];
		};
		
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
			[self.posFittingViewController presentViewControllerInPopover:self.posFittingViewController.itemsViewController
																 fromRect:[self.tableView rectForRowAtIndexPath:indexPath]
																   inView:self.tableView
												 permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
		else
			[self.posFittingViewController presentViewController:self.posFittingViewController.itemsViewController animated:YES completion:nil];
	};
	
	void (^unloadAmmo)(NSArray*) = ^(NSArray* structures){
		for (ItemInfo* itemInfo in structures) {
			eufe::Structure* structure = dynamic_cast<eufe::Structure*>(itemInfo.item);
			structure->clearCharge();
		}
		[self.posFittingViewController update];
	};
	
	void (^moduleInfo)(NSArray*) = ^(NSArray* modules){
		ItemViewController *itemViewController = [[ItemViewController alloc] initWithNibName:@"ItemViewController" bundle:nil];
		[itemInfo updateAttributes];
		itemViewController.type = itemInfo;
		[itemViewController setActivePage:ItemViewControllerActivePageInfo];
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
			UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:itemViewController];
			navController.modalPresentationStyle = UIModalPresentationFormSheet;
			[self.posFittingViewController presentViewController:navController animated:YES completion:nil];
		}
		else
			[self.posFittingViewController.navigationController pushViewController:itemViewController animated:YES];
	};
	void (^ammoInfo)(NSArray*) = ^(NSArray* modules){
		ItemViewController *itemViewController = [[ItemViewController alloc] initWithNibName:@"ItemViewController" bundle:nil];
		ItemInfo* ammo = [ItemInfo itemInfoWithItem:structure->getCharge() error:nil];
		[ammo updateAttributes];
		itemViewController.type = ammo;
		[itemViewController setActivePage:ItemViewControllerActivePageInfo];
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
			UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:itemViewController];
			navController.modalPresentationStyle = UIModalPresentationFormSheet;
			[self.posFittingViewController presentViewController:navController animated:YES completion:nil];
		}
		else
			[self.posFittingViewController.navigationController pushViewController:itemViewController animated:YES];
	};
	
		
	NSMutableArray* buttons = [NSMutableArray new];
	NSMutableArray* actions = [NSMutableArray new];
	
	[actions addObject:remove];
	
	[buttons addObject:ActionButtonShowModuleInfo];
	[actions addObject:moduleInfo];
	if (structure->getCharge() != NULL) {
		[buttons addObject:ActionButtonShowAmmoInfo];
		[actions addObject:ammoInfo];
	}
	
	eufe::Module::State state = structure->getState();
	if (state >= eufe::Module::STATE_ACTIVE) {
		[buttons addObject:ActionButtonOffline];
		[actions addObject:putOffline];
	}
	else {
		[buttons addObject:ActionButtonOnline];
		[actions addObject:putOnline];
	}
	
	[buttons addObject:ActionButtonAmount];
	[actions addObject:amount];
	
	if (chargeGroups.size() > 0) {
		[buttons addObject:ActionButtonAmmoCurrentModule];
		[actions addObject:setAmmo];
		
		if (multiple) {
			[buttons addObject:ActionButtonAmmoAllModules];
			[actions addObject:setAllModulesAmmo];
		}
		if (structure->getCharge() != nil) {
			[buttons addObject:ActionButtonUnloadAmmo];
			[actions addObject:unloadAmmo];
		}
	}
	
	[[UIActionSheet actionSheetWithStyle:UIActionSheetStyleBlackOpaque
								   title:nil
					   cancelButtonTitle:NSLocalizedString(@"Cancel", )
				  destructiveButtonTitle:ActionButtonDelete
					   otherButtonTitles:buttons
						 completionBlock:^(UIActionSheet *actionSheet, NSInteger selectedButtonIndex) {
							 if (selectedButtonIndex != actionSheet.cancelButtonIndex) {
								 void (^block)(NSArray*) = actions[selectedButtonIndex];
								 block(array);
							 }
						 } cancelBlock:nil] showInWindowFromRect:[self.tableView rectForRowAtIndexPath:indexPath] inView:self.tableView animated:YES];
}

@end
