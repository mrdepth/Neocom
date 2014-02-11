//
//  NCFittingPOSStructuresDataSource.m
//  Neocom
//
//  Created by Shimanski Artem on 11.02.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCFittingPOSStructuresDataSource.h"
#import "NCFittingPOSViewController.h"
#import "NCTableViewCell.h"
#import "NCFittingPOSStructureCell.h"
#import "NSNumberFormatter+Neocom.h"
#import "NSString+Neocom.h"
#import "UIActionSheet+Block.h"

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
#define ActionButtonShowStructureInfo NSLocalizedString(@"Show Structure Info", nil)
#define ActionButtonShowAmmoInfo NSLocalizedString(@"Show Ammo Info", nil)
#define ActionButtonAmount NSLocalizedString(@"Set Amount", nil)

@interface NCFittingPOSStructuresDataSourceRow : NSObject {
	eufe::StructuresList _structures;
}
@property (nonatomic, strong) EVEDBInvType* type;
@property (nonatomic, readonly) eufe::StructuresList& structures;
@end

@implementation NCFittingPOSStructuresDataSourceRow

@end

@interface NCFittingPOSStructuresDataSource()
@property (nonatomic, strong) NSArray* rows;
//@property (nonatomic, strong, readwrite) NCFittingShipDronesTableHeaderView* tableHeaderView;
@end

@implementation NCFittingPOSStructuresDataSource

- (void) reload {
	self.rows = nil;
	if (self.tableView.dataSource == self)
		[self.tableView reloadData];
	
	__block float totalPG;
	__block float usedPG;
	__block float totalCPU;
	__block float usedCPU;
	
	__block NSArray* rows = nil;
	[[self.controller taskManager] addTaskWithIndentifier:NCTaskManagerIdentifierAuto
													title:NCTaskManagerDefaultTitle
													block:^(NCTask *task) {
														@synchronized(self.controller) {
															eufe::ControlTower* controlTower = self.controller.engine->getControlTower();
															
															NSMutableDictionary* structuresDic = [NSMutableDictionary new];
															
															for (auto structure: controlTower->getStructures()) {
																NSInteger typeID = structure->getTypeID();
																NCFittingPOSStructuresDataSourceRow* row = structuresDic[@(typeID)];
																if (!row) {
																	row = [NCFittingPOSStructuresDataSourceRow new];
																	row.type = [self.controller typeWithItem:structure];
																	structuresDic[@(typeID)] = row;
																}
																row.structures.push_back(structure);
															}
															
															totalPG = controlTower->getTotalPowerGrid();
															usedPG = controlTower->getPowerGridUsed();
															
															totalCPU = controlTower->getTotalCpu();
															usedCPU = controlTower->getCpuUsed();
															
															rows = [[structuresDic allValues] sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"type.typeName" ascending:YES]]];
														}
													}
										completionHandler:^(NCTask *task) {
											if (![task isCancelled]) {
												self.rows = rows;
												
												if (self.tableView.dataSource == self)
													[self.tableView reloadData];
												
/*												self.tableHeaderView.droneBayLabel.text = [NSString stringWithTotalResources:totalDB usedResources:usedDB unit:@"m3"];
												self.tableHeaderView.droneBayLabel.progress = totalDB > 0 ? usedDB / totalDB : 0;
												self.tableHeaderView.droneBandwidthLabel.text = [NSString stringWithTotalResources:totalBandwidth usedResources:usedBandwidth unit:@"Mbit/s"];
												self.tableHeaderView.droneBandwidthLabel.progress = totalBandwidth > 0 ? usedBandwidth / totalBandwidth : 0;
												self.tableHeaderView.dronesCountLabel.text = [NSString stringWithFormat:@"%d/%d", activeDrones, maxActiveDrones];
												if (activeDrones > maxActiveDrones)
													self.tableHeaderView.dronesCountLabel.textColor = [UIColor redColor];
												else
													self.tableHeaderView.dronesCountLabel.textColor = [UIColor whiteColor];*/
												
											}
										}];
}


/*- (NCFittingShipDronesTableHeaderView*) tableHeaderView {
	if (!_tableHeaderView) {
		_tableHeaderView = [NCFittingShipDronesTableHeaderView viewWithNibName:@"NCFittingShipDronesTableHeaderView" bundle:nil];
	}
	return _tableHeaderView;
}*/

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.rows.count + 1;
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
	if (indexPath.row >= self.rows.count) {
		NCTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
		cell.imageView.image = [UIImage imageNamed:@"slotRig.png"];
		cell.textLabel.text = NSLocalizedString(@"Add Structure", nil);
		cell.detailTextLabel.text = nil;
		cell.accessoryView = nil;
		
		return cell;
	}
	else {
		NCFittingPOSStructuresDataSourceRow* row = self.rows[indexPath.row];
		eufe::Structure* structure = row.structures.front();
		
		int optimal = (int) structure->getMaxRange();
		int falloff = (int) structure->getFalloff();
		float trackingSpeed = structure->getTrackingSpeed();
		
		NCFittingPOSStructureCell* cell = [tableView dequeueReusableCellWithIdentifier:@"NCFittingPOSStructureCell"];
		
		cell.typeNameLabel.text = [NSString stringWithFormat:@"%@ (x%d)", row.type.typeName, (int) row.structures.size()];
		cell.typeImageView.image = [UIImage imageNamed:[row.type typeSmallImageName]];
		
		if (optimal > 0) {
			NSString *s = [NSString stringWithFormat:NSLocalizedString(@"%@m", nil), [NSNumberFormatter neocomLocalizedStringFromNumber:@(optimal)]];
			if (falloff > 0)
				s = [s stringByAppendingFormat:NSLocalizedString(@" + %@m", nil), [NSNumberFormatter neocomLocalizedStringFromNumber:@(falloff)]];
			if (trackingSpeed > 0)
				s = [s stringByAppendingFormat:NSLocalizedString(@" (%@ rad/sec)", nil), [NSNumberFormatter neocomLocalizedStringFromNumber:@(trackingSpeed)]];
			cell.optimalLabel.text = s;
		}
		else
			cell.optimalLabel.text = nil;
		
		switch (structure->getState()) {
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
		
		return cell;
	}
}



#pragma mark -
#pragma mark Table view delegate

- (CGFloat) tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return 44;
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	if (indexPath.row >= self.rows.count) {
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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell* cell = [tableView cellForRowAtIndexPath:indexPath];
	if (indexPath.row >= self.rows.count) {
		self.controller.typePickerViewController.title = NSLocalizedString(@"Structures", nil);
		
		[self.controller.typePickerViewController presentWithConditions:@[@"invTypes.groupID <> 365",
																		  @"invTypes.groupID = invGroups.groupID",
																		  @"invGroups.categoryID = 23"]
													   inViewController:self.controller
															   fromRect:cell.bounds
																 inView:cell
															   animated:YES
													  completionHandler:^(EVEDBInvType *type) {
														  eufe::ControlTower* controlTower = self.controller.engine->getControlTower();
														  eufe::Module::State state = eufe::Module::STATE_ACTIVE;
														  eufe::Charge* charge = nullptr;
														  for (auto structure: controlTower->getStructures()) {
															  if (structure->getTypeID() == type.typeID) {
																  state = structure->getState();
																  charge = structure->getCharge();
															  }
														  }
														  auto structure = controlTower->addStructure(type.typeID);
														  structure->setState(state);
														  if (charge)
															  structure->setCharge(charge->getTypeID());
														  [self.controller reload];
														  [self.controller dismissAnimated];
													  }];
	}
	else {
		[self performActionForRowAtIndexPath:indexPath];
	}
}

#pragma mark - Private

- (void) performActionForRowAtIndexPath:(NSIndexPath*) indexPath {
	UITableViewCell* cell = [self.tableView cellForRowAtIndexPath:indexPath];
	NCFittingPOSStructuresDataSourceRow* row = self.rows[indexPath.row];
	
	eufe::ControlTower* controlTower = self.controller.engine->getControlTower();
	eufe::Structure* structure = row.structures.front();
	
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
	
	void (^remove)(eufe::StructuresList) = ^(eufe::StructuresList structures){
		for (auto structure: structures)
			controlTower->removeStructure(structure);
		[self.controller reload];
	};
	
	void (^putOffline)(eufe::StructuresList) = ^(eufe::StructuresList structures){
		for (auto structure: structures)
			structure->setState(eufe::Module::STATE_OFFLINE);
		[self.controller reload];
	};

	void (^putOnline)(eufe::StructuresList) = ^(eufe::StructuresList structures){
		for (auto structure: structures)
			structure->setState(eufe::Module::STATE_ACTIVE);
		[self.controller reload];
	};

	void (^setAmount)(eufe::StructuresList) = ^(eufe::StructuresList structures) {
		NSMutableArray* array = [NSMutableArray new];
		for (auto structure: structures)
			[array addObject:[NSValue valueWithPointer:structure]];
		[self.controller performSegueWithIdentifier:@"NCFittingAmountViewController" sender:array];
	};
	
	void (^setAmmo)(eufe::StructuresList) = ^(eufe::StructuresList structures){
		int chargeSize = structure->getChargeSize();
		
		NSMutableArray *groups = [NSMutableArray new];
		for (auto i: structure->getChargeGroups())
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
						   [NSString stringWithFormat:@"invTypes.volume <= %f", structure->getAttribute(eufe::CAPACITY_ATTRIBUTE_ID)->getValue()]];
		
		[self.controller.typePickerViewController presentWithConditions:conditions
													   inViewController:self.controller
															   fromRect:cell.bounds
																 inView:cell
															   animated:YES
													  completionHandler:^(EVEDBInvType *type) {
														  for (auto structure: structures)
															  structure->setCharge(type.typeID);
														  [self.controller reload];
														  [self.controller dismissAnimated];
													  }];
	};
	
	void (^setAllModulesAmmo)(NSArray*) = ^(NSArray* structures){
		int chargeSize = structure->getChargeSize();
		
		NSMutableArray *groups = [NSMutableArray new];
		for (auto i: structure->getChargeGroups())
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
						   [NSString stringWithFormat:@"invTypes.volume <= %f", structure->getAttribute(eufe::CAPACITY_ATTRIBUTE_ID)->getValue()]];
		
		[self.controller.typePickerViewController presentWithConditions:conditions
													   inViewController:self.controller
															   fromRect:cell.bounds
																 inView:cell
															   animated:YES
													  completionHandler:^(EVEDBInvType *type) {
														  for (auto structure: controlTower->getStructures())
															  structure->setCharge(type.typeID);
														  [self.controller reload];
														  [self.controller dismissAnimated];
													  }];
	};

	
	void (^unloadAmmo)(eufe::StructuresList) = ^(eufe::StructuresList structures){
		for (auto structure: structures)
			structure->clearCharge();
		[self.controller reload];
	};
	
	void (^structureInfo)(eufe::StructuresList) = ^(eufe::StructuresList structures){
		[self.controller performSegueWithIdentifier:@"NCDatabaseTypeInfoViewController" sender:[NSValue valueWithPointer:structure]];
	};
	void (^ammoInfo)(eufe::StructuresList) = ^(eufe::StructuresList structures){
		[self.controller performSegueWithIdentifier:@"NCDatabaseTypeInfoViewController" sender:[NSValue valueWithPointer:structure->getCharge()]];
	};
	
	NSMutableArray* buttons = [NSMutableArray new];
	NSMutableArray* actions = [NSMutableArray new];
	
	[actions addObject:remove];
	
	[buttons addObject:ActionButtonShowStructureInfo];
	[actions addObject:structureInfo];
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
	[actions addObject:setAmount];
	
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
								 void (^block)(eufe::StructuresList) = actions[selectedButtonIndex];
								 block(row.structures);
							 }
						 } cancelBlock:nil] showFromRect:cell.bounds inView:cell animated:YES];
}

@end
