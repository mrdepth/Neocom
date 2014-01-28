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
#import "NCFittingModuleCell.h"
#import "NSNumberFormatter+Neocom.h"
#import "NCFittingSectionGenericHedaerView.h"

@interface NCFittingShipModulesDataSourceSection : NSObject
@property (nonatomic, assign) std::vector<eufe::Module*> modules;
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


@end

@implementation NCFittingShipModulesDataSource
@synthesize tableHeaderView = _tableHeaderView;

- (void) reload {
	__block float totalPG;
	__block float usedPG;
	__block float totalCPU;
	__block float usedCPU;
	__block float totalCalibration;
	__block float usedCalibration;
	
	NSMutableArray* sections = [NSMutableArray new];
	[[self.controller taskManager] addTaskWithIndentifier:NCTaskManagerIdentifierAuto
													title:NCTaskManagerDefaultTitle
													block:^(NCTask *task) {
														eufe::Ship* ship = self.controller.character->getShip();
														
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
																section.modules = std::vector<eufe::Module*>(modules.begin(), modules.end());
																[sections addObject:section];
															}
														}
														
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
										completionHandler:^(NCTask *task) {
											if (![task isCancelled]) {
												self.sections = sections;
												self.tableHeaderView.powerGridLabel.text = [NSString stringWithTotalResources:totalPG usedResources:usedPG unit:@"MW"];
												self.tableHeaderView.powerGridLabel.progress = totalPG > 0 ? usedPG / totalPG : 0;
												self.tableHeaderView.cpuLabel.text = [NSString stringWithTotalResources:totalCPU usedResources:usedCPU unit:@"tf"];
												self.tableHeaderView.cpuLabel.progress = usedCPU > 0 ? usedCPU / totalCPU : 0;
												self.tableHeaderView.calibrationLabel.text = [NSString stringWithFormat:@"%d/%d", (int) usedCalibration, (int) totalCalibration];
												self.tableHeaderView.calibrationLabel.progress = totalCalibration > 0 ? usedCalibration / totalCalibration : 0;

												if (self.controller.tableView.dataSource == self)
													[self.controller.tableView reloadData];
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
	return std::max(section.numberOfSlots, static_cast<int>(section.modules.size()));
}

- (UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	NCFittingShipModulesDataSourceSection* section = self.sections[indexPath.section];
	if (indexPath.row >= section.modules.size()) {
		NCTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
		switch (section.slot) {
			case eufe::Module::SLOT_HI:
				cell.imageView.image = [UIImage imageNamed:@"slotHigh.png"];
				cell.textLabel.text = NSLocalizedString(@"High slot", nil);
				break;
			case eufe::Module::SLOT_MED:
				cell.imageView.image = [UIImage imageNamed:@"slotMed.png"];
				cell.textLabel.text = NSLocalizedString(@"Med slot", nil);
				break;
			case eufe::Module::SLOT_LOW:
				cell.imageView.image = [UIImage imageNamed:@"slotLow.png"];
				cell.textLabel.text = NSLocalizedString(@"Low slot", nil);
				break;
			case eufe::Module::SLOT_RIG:
				cell.imageView.image = [UIImage imageNamed:@"slotRig.png"];
				cell.textLabel.text = NSLocalizedString(@"Rig slot", nil);
				break;
			case eufe::Module::SLOT_SUBSYSTEM:
				cell.imageView.image = [UIImage imageNamed:@"slotSubsystem.png"];
				cell.textLabel.text = NSLocalizedString(@"Subsystem slot", nil);
				break;
			default:
				cell.imageView.image = nil;
				cell.textLabel.text = nil;
		}
		return cell;
	}
	else {
		NCFittingModuleCell* cell = [tableView dequeueReusableCellWithIdentifier:@"NCFittingModuleCell"];
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

		return cell;
	}
}

#pragma mark - Table view delegate

- (UIView*) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)sectionIndex {
	NCFittingShipModulesDataSourceSection* section = self.sections[sectionIndex];
	
	if (section.slot == eufe::Module::SLOT_HI) {
		NCFittingSectionGenericHedaerView* header = [tableView dequeueReusableHeaderFooterViewWithIdentifier:@"NCFittingSectionGenericHedaerView"];
		return header;
	}
	else {
		NCFittingSectionGenericHedaerView* header = [tableView dequeueReusableHeaderFooterViewWithIdentifier:@"NCFittingSectionGenericHedaerView"];
		switch (section.slot) {
			case eufe::Module::SLOT_HI:
				header.imageView.image = [UIImage imageNamed:@"slotHigh.png"];
				header.titleLabel.text = NSLocalizedString(@"High slot", nil);
				break;
			case eufe::Module::SLOT_MED:
				header.imageView.image = [UIImage imageNamed:@"slotMed.png"];
				header.titleLabel.text = NSLocalizedString(@"Med slot", nil);
				break;
			case eufe::Module::SLOT_LOW:
				header.imageView.image = [UIImage imageNamed:@"slotLow.png"];
				header.titleLabel.text = NSLocalizedString(@"Low slot", nil);
				break;
			case eufe::Module::SLOT_RIG:
				header.imageView.image = [UIImage imageNamed:@"slotRig.png"];
				header.titleLabel.text = NSLocalizedString(@"Rig slot", nil);
				break;
			case eufe::Module::SLOT_SUBSYSTEM:
				header.imageView.image = [UIImage imageNamed:@"slotSubsystem.png"];
				header.titleLabel.text = NSLocalizedString(@"Subsystem slot", nil);
				break;
			default:
				header.imageView.image = nil;
				header.titleLabel.text = nil;
		}
		return header;
	}
}

- (CGFloat) tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return 44;
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	NCFittingShipModulesDataSourceSection* section = self.sections[indexPath.section];
	if (indexPath.row >= section.modules.size()) {
		return 44;
	}
	else {
		UITableViewCell* cell = [self tableView:tableView cellForRowAtIndexPath:indexPath];
		cell.bounds = CGRectMake(0, 0, CGRectGetWidth(tableView.bounds), CGRectGetHeight(cell.bounds));
		[cell setNeedsLayout];
		[cell layoutIfNeeded];
		return [cell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height + 1.0;
	}
}

@end
