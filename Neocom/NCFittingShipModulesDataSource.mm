//
//  NCFittingShipModulesDataSource.m
//  Neocom
//
//  Created by Артем Шиманский on 28.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCFittingShipModulesDataSource.h"
#import "NCFittingShipViewController.h"
#import "NCFittingShipModulesTableHeaderView.h"
#import "UIView+Nib.h"
#import "NSString+Neocom.h"
#import <algorithm>
#import "NCTableViewCell.h"
#import "NCFittingShipModuleCell.h"
#import "NSNumberFormatter+Neocom.h"
#import "NCFittingSectionGenericHedaerView.h"
#import "UIActionSheet+Block.h"
#import "NCFittingSectionHiSlotHedaerView.h"

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
#define ActionButtonAffectingSkills NSLocalizedString(@"Affecting Skills", nil)


@interface NCFittingShipModulesDataSourceSection : NSObject {
	std::vector<eufe::Module*> _modules;
}
@property (nonatomic, readonly) std::vector<eufe::Module*>& modules;
@property (nonatomic, assign) eufe::Module::Slot slot;
@property (nonatomic, assign) int numberOfSlots;
@end

@implementation NCFittingShipModulesDataSourceSection

@end

@interface NCFittingShipModulesDataSource()
@property (nonatomic, assign) int usedTurretHardpoints;
@property (nonatomic, assign) int totalTurretHardpoints;
@property (nonatomic, assign) int usedMissileHardpoints;
@property (nonatomic, assign) int totalMissileHardpoints;

@property (nonatomic, strong) NSArray* sections;

@property (nonatomic, strong, readwrite) NCFittingShipModulesTableHeaderView* tableHeaderView;
@property (nonatomic, strong) NCFittingShipModuleCell* offscreenCell;

- (void) tableView:(UITableView *)tableView configureCell:(UITableViewCell*) tableViewCell forRowAtIndexPath:(NSIndexPath*) indexPath;

@end

@implementation NCFittingShipModulesDataSource
@synthesize tableHeaderView = _tableHeaderView;

- (void) reload {
	__block float totalPG = 0;
	__block float usedPG = 0;
	__block float totalCPU = 0;
	__block float usedCPU = 0;
	__block float totalCalibration = 0;
	__block float usedCalibration = 0;
	
	NSMutableArray* sections = [NSMutableArray new];
	if (!self.controller.fit.pilot)
		return;
	
	eufe::Ship* ship = self.controller.fit.pilot->getShip();
	
	eufe::Module::Slot slots[] = {eufe::Module::SLOT_HI, eufe::Module::SLOT_MED, eufe::Module::SLOT_LOW, eufe::Module::SLOT_RIG, eufe::Module::SLOT_SUBSYSTEM};
	int n = sizeof(slots) / sizeof(eufe::Module::Slot);
	
	for (int i = 0; i < n; i++) {
		int numberOfSlots = ship->getNumberOfSlots(slots[i]);
		if (numberOfSlots > 0) {
			eufe::ModulesList modules;
			ship->getModules(slots[i], std::inserter(modules, modules.end()));
			
			NCFittingShipModulesDataSourceSection* section = [NCFittingShipModulesDataSourceSection new];
			section.slot = slots[i];
			section.numberOfSlots = numberOfSlots;
			section.modules.insert(section.modules.begin(), modules.begin(), modules.end());
			[sections addObject:section];
		}
	}
	self.sections = sections;

	if (self.tableView.dataSource == self) {
		[self.tableView reloadData];
	}

	[[self.controller taskManager] addTaskWithIndentifier:NCTaskManagerIdentifierAuto
													title:NCTaskManagerDefaultTitle
													block:^(NCTask *task) {
														@synchronized(self.controller) {
															
															totalPG = ship->getTotalPowerGrid();
															usedPG = ship->getPowerGridUsed();
															
															totalCPU = ship->getTotalCpu();
															usedCPU = ship->getCpuUsed();
															
															totalCalibration = ship->getTotalCalibration();
															usedCalibration = ship->getCalibrationUsed();
															
															self.usedTurretHardpoints = ship->getUsedHardpoints(eufe::Module::HARDPOINT_TURRET);
															self.totalTurretHardpoints = ship->getNumberOfHardpoints(eufe::Module::HARDPOINT_TURRET);
															self.usedMissileHardpoints = ship->getUsedHardpoints(eufe::Module::HARDPOINT_LAUNCHER);
															self.totalMissileHardpoints = ship->getNumberOfHardpoints(eufe::Module::HARDPOINT_LAUNCHER);
														}
													}
										completionHandler:^(NCTask *task) {
											if (![task isCancelled]) {
												self.tableHeaderView.powerGridLabel.text = [NSString stringWithTotalResources:totalPG usedResources:usedPG unit:@"MW"];
												self.tableHeaderView.powerGridLabel.progress = totalPG > 0 ? usedPG / totalPG : 0;
												self.tableHeaderView.cpuLabel.text = [NSString stringWithTotalResources:totalCPU usedResources:usedCPU unit:@"tf"];
												self.tableHeaderView.cpuLabel.progress = usedCPU > 0 ? usedCPU / totalCPU : 0;
												self.tableHeaderView.calibrationLabel.text = [NSString stringWithFormat:@"%d/%d", (int) usedCalibration, (int) totalCalibration];
												self.tableHeaderView.calibrationLabel.progress = totalCalibration > 0 ? usedCalibration / totalCalibration : 0;

												if (self.tableView.dataSource == self) {
													[self.tableView reloadData];
												}
											}
										}];
}

- (NCFittingShipModulesTableHeaderView*) tableHeaderView {
	if (!_tableHeaderView) {
		_tableHeaderView = [NCFittingShipModulesTableHeaderView viewWithNibName:@"NCFittingShipModulesTableHeaderView" bundle:nil];
	}
	return _tableHeaderView;
}

#pragma mark - Table view data source

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
	return self.sections.count;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)sectionIndex {
	NCFittingShipModulesDataSourceSection* section = self.sections[sectionIndex];
	if (!section)
		return 0;
	else
		return std::max(section.numberOfSlots, static_cast<int>(section.modules.size()));
}

- (UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	NCFittingShipModulesDataSourceSection* section = self.sections[indexPath.section];
	if (indexPath.row >= section.modules.size()) {
		NCTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
		[self tableView:tableView configureCell:cell forRowAtIndexPath:indexPath];
		return cell;
	}
	else {
		NCFittingShipModuleCell* cell = [tableView dequeueReusableCellWithIdentifier:@"NCFittingShipModuleCell"];
		[self tableView:tableView configureCell:cell forRowAtIndexPath:indexPath];
		return cell;
	}
}

#pragma mark - Table view delegate

- (UIView*) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)sectionIndex {
	NCFittingShipModulesDataSourceSection* section = self.sections[sectionIndex];
	
	if (section.slot == eufe::Module::SLOT_HI) {
		NCFittingSectionHiSlotHedaerView* header = [tableView dequeueReusableHeaderFooterViewWithIdentifier:@"NCFittingSectionHiSlotHedaerView"];
		header.turretsLabel.text = [NSString stringWithFormat:@"%d/%d", self.usedTurretHardpoints, self.totalTurretHardpoints];
		header.launchersLabel.text = [NSString stringWithFormat:@"%d/%d", self.usedMissileHardpoints, self.totalMissileHardpoints];
		return header;
	}
	else {
		NCFittingSectionGenericHedaerView* header = [tableView dequeueReusableHeaderFooterViewWithIdentifier:@"NCFittingSectionGenericHedaerView"];
		switch (section.slot) {
			case eufe::Module::SLOT_MED:
				header.imageView.image = [UIImage imageNamed:@"slotMed.png"];
				header.titleLabel.text = NSLocalizedString(@"Med slots", nil);
				break;
			case eufe::Module::SLOT_LOW:
				header.imageView.image = [UIImage imageNamed:@"slotLow.png"];
				header.titleLabel.text = NSLocalizedString(@"Low slots", nil);
				break;
			case eufe::Module::SLOT_RIG:
				header.imageView.image = [UIImage imageNamed:@"slotRig.png"];
				header.titleLabel.text = NSLocalizedString(@"Rig slots", nil);
				break;
			case eufe::Module::SLOT_SUBSYSTEM:
				header.imageView.image = [UIImage imageNamed:@"slotSubsystem.png"];
				header.titleLabel.text = NSLocalizedString(@"Subsystem slots", nil);
				break;
			default:
				header.imageView.image = nil;
				header.titleLabel.text = nil;
		}
		return header;
	}
}

- (CGFloat) tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return 41;
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	NCFittingShipModulesDataSourceSection* section = self.sections[indexPath.section];
	if (indexPath.row >= section.modules.size()) {
		return 41;
	}
	else {
		if (!self.offscreenCell)
			self.offscreenCell = [tableView dequeueReusableCellWithIdentifier:@"NCFittingShipModuleCell"];
		[self tableView:tableView configureCell:self.offscreenCell forRowAtIndexPath:indexPath];
		self.offscreenCell.bounds = CGRectMake(0, 0, CGRectGetWidth(tableView.bounds), CGRectGetHeight(self.offscreenCell.bounds));
		[self.offscreenCell setNeedsLayout];
		[self.offscreenCell layoutIfNeeded];
		return [self.offscreenCell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height + 1.5;
	}
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	NCFittingShipModulesDataSourceSection* section = self.sections[indexPath.section];
	UITableViewCell* cell = [tableView cellForRowAtIndexPath:indexPath];
	if (indexPath.row >= section.modules.size()) {
		eufe::Ship* ship = self.controller.fit.pilot->getShip();
		NSString* title;
		NSArray* conditions;
		switch (section.slot) {
			case eufe::Module::SLOT_HI:
				conditions = @[@"dgmTypeEffects.typeID = invTypes.typeID", @"dgmTypeEffects.effectID = 12"];
				title = NSLocalizedString(@"Hi slot", nil);
				break;
			case eufe::Module::SLOT_MED:
				conditions = @[@"dgmTypeEffects.typeID = invTypes.typeID", @"dgmTypeEffects.effectID = 13"];
				title = NSLocalizedString(@"Med slot", nil);
				break;
			case eufe::Module::SLOT_LOW:
				conditions = @[@"dgmTypeEffects.typeID = invTypes.typeID", @"dgmTypeEffects.effectID = 11"];
				title = NSLocalizedString(@"Low slot", nil);
				break;
			case eufe::Module::SLOT_RIG:
				conditions = @[@"dgmTypeEffects.typeID = invTypes.typeID",
							   @"dgmTypeEffects.effectID = 2663",
							   @"dgmTypeAttributes.typeID = invTypes.typeID",
							   @"dgmTypeAttributes.attributeID = 1547",
							   [NSString stringWithFormat:@"dgmTypeAttributes.value = %d", static_cast<int>(ship->getAttribute(1547)->getValue())]];
				title = NSLocalizedString(@"Rigs", nil);
				break;
			case eufe::Module::SLOT_SUBSYSTEM: {
				int32_t raceID = static_cast<int32_t>(ship->getAttribute(eufe::RACE_ID_ATTRIBUTE_ID)->getValue());
				switch(raceID) {
					case 1: //Caldari
						title = NSLocalizedString(@"Caldari Subsystems", nil);
						break;
					case 2: //Minmatar
						title = NSLocalizedString(@"Minmatar Subsystems", nil);
						break;
					case 4: //Amarr
						title = NSLocalizedString(@"Amarr Subsystems", nil);
						break;
					case 8: //Gallente
						title = NSLocalizedString(@"Gallente Subsystems", nil);
						break;
				}
				conditions = @[@"dgmTypeEffects.typeID = invTypes.typeID",
							   @"dgmTypeEffects.effectID = 3772",
							   [NSString stringWithFormat:@"invTypes.raceID=%d", raceID]];
				break;
			}
			default:
				return;
		}
		self.controller.typePickerViewController.title = title;
		[self.controller.typePickerViewController presentWithConditions:conditions
													   inViewController:self.controller
															   fromRect:cell.bounds
																 inView:cell
															   animated:YES
													  completionHandler:^(EVEDBInvType *type) {
														  ship->addModule(type.typeID);
														  [self.controller reload];
														  if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
															  [self.controller dismissAnimated];
													  }];
	}
	else {
		[self performActionForRowAtIndexPath:indexPath];
	}
}

#pragma mark - Private

- (void) tableView:(UITableView *)tableView configureCell:(UITableViewCell*) tableViewCell forRowAtIndexPath:(NSIndexPath*) indexPath {
	NCFittingShipModulesDataSourceSection* section = self.sections[indexPath.section];
	if (indexPath.row >= section.modules.size()) {
		NCTableViewCell* cell = (NCTableViewCell*) tableViewCell;
		cell.subtitleLabel.text = nil;
		cell.accessoryView = nil;
		switch (section.slot) {
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
	}
	else {
		NCFittingShipModuleCell* cell = (NCFittingShipModuleCell*) tableViewCell;
		eufe::Module* module = section.modules[indexPath.row];
		EVEDBInvType* type = [self.controller typeWithItem:module];
		cell.typeNameLabel.text = type.typeName;
		cell.typeImageView.image = [UIImage imageNamed:[type typeSmallImageName]];
		
		eufe::Charge* charge = module->getCharge();
		
		if (charge) {
			type = [self.controller typeWithItem:charge];
			cell.chargeLabel.text = type.typeName;
		}
		else
			cell.chargeLabel.text = nil;
		
		int optimal = (int) module->getMaxRange();
		int falloff = (int) module->getFalloff();
		float trackingSpeed = module->getTrackingSpeed();
		float lifeTime = module->getLifeTime();
		
		if (optimal > 0) {
			NSMutableString* s = [NSMutableString stringWithFormat:NSLocalizedString(@"%@m", nil), [NSNumberFormatter neocomLocalizedStringFromNumber:@(optimal)]];
			if (falloff > 0)
				[s appendFormat:NSLocalizedString(@" + %@m", nil), [NSNumberFormatter neocomLocalizedStringFromNumber:@(falloff)]];
			if (trackingSpeed > 0)
				[s appendFormat:NSLocalizedString(@" (%@ rad/sec)", nil), [NSNumberFormatter neocomLocalizedStringFromNumber:@(trackingSpeed)]];
			cell.optimalLabel.text = s;
		}
		else
			cell.optimalLabel.text = nil;
		
		if (lifeTime > 0)
			cell.lifetimeLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Lifetime: %@", nil), [NSString stringWithTimeLeft:lifeTime]];
		else
			cell.lifetimeLabel.text = nil;
		
		eufe::Module::Slot slot = module->getSlot();
		if (slot == eufe::Module::SLOT_HI || slot == eufe::Module::SLOT_MED || slot == eufe::Module::SLOT_LOW) {
			switch (module->getState()) {
				case eufe::Module::STATE_ACTIVE:
					cell.stateImageView.image = [UIImage imageNamed:@"active.png"];
					break;
				case eufe::Module::STATE_ONLINE:
					cell.stateImageView.image = [UIImage imageNamed:@"online.png"];
					break;
				case eufe::Module::STATE_OVERLOADED:
					cell.stateImageView.image = [UIImage imageNamed:@"overheated.png"];
					break;
				default:
					cell.stateImageView.image = [UIImage imageNamed:@"offline.png"];
					break;
			}
		}
		else
			cell.stateImageView.image = nil;
		
		cell.targetImageView.image = module->getTarget() != NULL ? [UIImage imageNamed:@"Icons/icon04_12.png"] : nil;
	}
}

- (void) performActionForRowAtIndexPath:(NSIndexPath*) indexPath {
	NCFittingShipModulesDataSourceSection* section = self.sections[indexPath.section];
	UITableViewCell* cell = [self.tableView cellForRowAtIndexPath:indexPath];
	
	eufe::Ship* ship = self.controller.fit.pilot->getShip();
	eufe::Module* module = section.modules[indexPath.row];
	EVEDBInvType* type = [self.controller typeWithItem:module];
	
	//NSMutableArray* allSimilarModules = [NSMutableArray new];
	eufe::ModulesList allSimilarModules;
	
	bool multiple = false;
	for (auto module: section.modules) {
		EVEDBInvType* moduleType = [self.controller typeWithItem:module];
		if (type.marketGroupID == moduleType.marketGroupID)
			allSimilarModules.push_back(module);
	}
	multiple = allSimilarModules.size() > 1;
	
	
	eufe::Module::State state = module->getState();
	
	void (^remove)(eufe::ModulesList) = ^(eufe::ModulesList modules){
		for (auto module: modules) {
			section.modules.erase(std::find(section.modules.begin(), section.modules.end(), module));
			ship->removeModule(module);
		}
		[self.controller reload];
	};
	
	void (^putOffline)(eufe::ModulesList) = ^(eufe::ModulesList modules){
		for (auto module: modules)
			module->setState(eufe::Module::STATE_OFFLINE);
		[self.controller reload];
	};
	void (^putOnline)(eufe::ModulesList) = ^(eufe::ModulesList modules){
		for (auto module: modules) {
			if (module->canHaveState(eufe::Module::STATE_ACTIVE))
				module->setState(eufe::Module::STATE_ACTIVE);
			else
				module->setState(eufe::Module::STATE_ONLINE);
		}
		[self.controller reload];
	};
	void (^activate)(eufe::ModulesList) = ^(eufe::ModulesList modules){
		for (auto module: modules)
			module->setState(eufe::Module::STATE_ACTIVE);
		[self.controller reload];
	};
	void (^deactivate)(eufe::ModulesList) = ^(eufe::ModulesList modules){
		for (auto module: modules)
			module->setState(eufe::Module::STATE_ONLINE);
		[self.controller reload];
	};
	void (^enableOverheating)(eufe::ModulesList) = ^(eufe::ModulesList modules){
		for (auto module: modules)
			module->setState(eufe::Module::STATE_OVERLOADED);
		[self.controller reload];
	};
	void (^disableOverheating)(eufe::ModulesList) = ^(eufe::ModulesList modules){
		for (auto module: modules)
			module->setState(eufe::Module::STATE_ACTIVE);
		[self.controller reload];
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
	
	void (^setAmmo)(eufe::ModulesList) = ^(eufe::ModulesList modules){
		int chargeSize = module->getChargeSize();
		
		NSMutableArray *groups = [NSMutableArray new];
		for (auto i: module->getChargeGroups())
			[groups addObject:[NSString stringWithFormat:@"%d", i]];
		
		self.controller.typePickerViewController.title = NSLocalizedString(@"Ammo", nil);
		NSArray* conditions;
		if (chargeSize)
			conditions = @[@"invTypes.typeID=dgmTypeAttributes.typeID",
						   @"dgmTypeAttributes.attributeID=128",
						   [NSString stringWithFormat:@"dgmTypeAttributes.value=%d", chargeSize],
						   [NSString stringWithFormat:@"groupID IN (%@)", [groups componentsJoinedByString:@","]]];
		else
			conditions = @[[NSString stringWithFormat:@"groupID IN (%@)", [groups componentsJoinedByString:@","]],
						   [NSString stringWithFormat:@"invTypes.volume <= %f", module->getAttribute(eufe::CAPACITY_ATTRIBUTE_ID)->getValue()]];
		
		[self.controller.typePickerViewController presentWithConditions:conditions
													   inViewController:self.controller
															   fromRect:cell.bounds
																 inView:cell
															   animated:YES
													  completionHandler:^(EVEDBInvType *type) {
														  for (auto module: modules)
															  module->setCharge(type.typeID);
														  [self.controller reload];
														  [self.controller dismissAnimated];
													  }];
	};
	void (^unloadAmmo)(eufe::ModulesList) = ^(eufe::ModulesList modules){
		for (auto module: modules)
			module->clearCharge();
		[self.controller reload];
	};
	
	void (^changeState)(eufe::ModulesList) = ^(eufe::ModulesList modules){
		[[UIActionSheet actionSheetWithStyle:UIActionSheetStyleBlackTranslucent
									   title:nil
						   cancelButtonTitle:NSLocalizedString(@"Cancel", )
					  destructiveButtonTitle:nil
						   otherButtonTitles:statesButtons
							 completionBlock:^(UIActionSheet *actionSheet, NSInteger selectedButtonIndex) {
								 if (selectedButtonIndex != actionSheet.cancelButtonIndex) {
									 void (^block)(eufe::ModulesList) = statesActions[selectedButtonIndex];
									 eufe::ModulesList modules;
									 modules.push_back(module);
									 block(modules);
								 }
							 } cancelBlock:nil] showFromRect:cell.bounds inView:cell animated:YES];
	};
	
	void (^moduleInfo)(eufe::ModulesList) = ^(eufe::ModulesList modules){
		[self.controller performSegueWithIdentifier:@"NCDatabaseTypeInfoViewController"
											 sender:@{@"sender": cell, @"object": [NSValue valueWithPointer:module]}];
	};
	void (^ammoInfo)(eufe::ModulesList) = ^(eufe::ModulesList modules){
		[self.controller performSegueWithIdentifier:@"NCDatabaseTypeInfoViewController"
											 sender:@{@"sender": cell, @"object": [NSValue valueWithPointer:module->getCharge()]}];
	};
	
	void (^setTarget)(eufe::ModulesList) = ^(eufe::ModulesList modules){
		NSMutableArray* array = [NSMutableArray new];
		for (auto module: modules)
			[array addObject:[NSValue valueWithPointer:module]];
		[self.controller performSegueWithIdentifier:@"NCFittingTargetsViewController"
											 sender:@{@"sender": cell, @"object": array}];
	};
	void (^clearTarget)(eufe::ModulesList) = ^(eufe::ModulesList modules){
		for (auto module: modules)
			module->clearTarget();
		[self.controller reload];
	};
	
	void (^variations)(eufe::ModulesList) = ^(eufe::ModulesList modules){
		NSMutableArray* array = [NSMutableArray new];
		for (auto module: modules)
			[array addObject:[NSValue valueWithPointer:module]];
		
		[self.controller performSegueWithIdentifier:@"NCFittingTypeVariationsViewController"
											 sender:@{@"sender": cell, @"object": array}];
	};
	
	void (^similarModules)(eufe::ModulesList) = ^(eufe::ModulesList modules){
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
		
		if (module->requireTarget() && self.controller.fits.count > 1) {
			[buttons addObject:ActionButtonSetTarget];
			[actions addObject:setTarget];
			if (module->getTarget() != NULL) {
				[buttons addObject:ActionButtonClearTarget];
				[actions addObject:clearTarget];
			}
		}
		
		[[UIActionSheet actionSheetWithStyle:UIActionSheetStyleBlackTranslucent
									   title:nil
						   cancelButtonTitle:NSLocalizedString(@"Cancel", )
					  destructiveButtonTitle:ActionButtonDelete
						   otherButtonTitles:buttons
							 completionBlock:^(UIActionSheet *actionSheet, NSInteger selectedButtonIndex) {
								 if (selectedButtonIndex != actionSheet.cancelButtonIndex) {
									 void (^block)(eufe::ModulesList) = actions[selectedButtonIndex];
									 block(allSimilarModules);
								 }
							 } cancelBlock:nil] showFromRect:cell.bounds inView:cell animated:YES];
	};
	
	void (^affectingSkills)(eufe::ModulesList) = ^(eufe::ModulesList modules){
		[self.controller performSegueWithIdentifier:@"NCFittingShipAffectingSkillsViewController"
											 sender:@{@"sender": cell, @"object": [NSValue valueWithPointer:module]}];
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
	if (module->requireTarget() && self.controller.fits.count > 1) {
		[buttons addObject:ActionButtonSetTarget];
		[actions addObject:setTarget];
		if (module->getTarget() != NULL) {
			[buttons addObject:ActionButtonClearTarget];
			[actions addObject:clearTarget];
		}
	}
	[buttons addObject:ActionButtonVariations];
	[actions addObject:variations];

	[buttons addObject:ActionButtonAffectingSkills];
	[actions addObject:affectingSkills];

	if (multiple) {
		[buttons addObject:ActionButtonAllSimilarModules];
		[actions addObject:similarModules];
	}
	
	[[UIActionSheet actionSheetWithStyle:UIActionSheetStyleBlackTranslucent
								   title:nil
					   cancelButtonTitle:NSLocalizedString(@"Cancel", )
				  destructiveButtonTitle:ActionButtonDelete
					   otherButtonTitles:buttons
						 completionBlock:^(UIActionSheet *actionSheet, NSInteger selectedButtonIndex) {
							 if (selectedButtonIndex != actionSheet.cancelButtonIndex) {
								 void (^block)(eufe::ModulesList) = actions[selectedButtonIndex];
								 eufe::ModulesList modules;
								 modules.push_back(module);
								 block(modules);
							 }
						 } cancelBlock:nil] showFromRect:cell.bounds inView:cell animated:YES];
}

@end
