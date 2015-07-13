//
//  NCFittingPOSStructuresViewController.m
//  Neocom
//
//  Created by Артем Шиманский on 15.06.15.
//  Copyright (c) 2015 Artem Shimanski. All rights reserved.
//

#import "NCFittingPOSStructuresViewController.h"
#import "NCFittingPOSViewController.h"
#import "NCTableViewCell.h"
#import "NCFittingPOSStructureCell.h"
#import "NSNumberFormatter+Neocom.h"
#import "NSString+Neocom.h"
#import "UIActionSheet+Block.h"
#import "UIView+Nib.h"
#import "NCFittingAmountCell.h"

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

@interface NCFittingPOSStructuresViewControllerRow : NSObject {
	eufe::StructuresList _structures;
}
@property (nonatomic, strong) NCDBInvType* type;
@property (nonatomic, readonly) eufe::StructuresList& structures;
@end

@interface NCFittingPOSStructuresViewControllerPickerRow : NSObject
@property (nonatomic, strong) NCFittingPOSStructuresViewControllerRow* associatedRow;
@end


@implementation NCFittingPOSStructuresViewControllerRow

@end

@implementation NCFittingPOSStructuresViewControllerPickerRow

@end

@interface NCFittingPOSStructuresViewController()<UIPickerViewDataSource, UIPickerViewDelegate>
@property (nonatomic, strong) NCDBInvType* activeAmountType;
@property (nonatomic, assign) NSInteger maximumAmount;
@property (nonatomic, strong) NSArray* rows;

- (void) performActionForRowAtIndexPath:(NSIndexPath*) indexPath;
- (void) tableView:(UITableView *)tableView configureCell:(UITableViewCell*) tableViewCell forRowAtIndexPath:(NSIndexPath*) indexPath;

@end

@implementation NCFittingPOSStructuresViewController

- (void) reload {
	if (self.tableView.dataSource == self)
		[self.tableView reloadData];
	
	__block float totalPG;
	__block float usedPG;
	__block float totalCPU;
	__block float usedCPU;
	
	__block NSMutableArray* rows = nil;
	[[self taskManager] addTaskWithIndentifier:NCTaskManagerIdentifierAuto
													title:NCTaskManagerDefaultTitle
													block:^(NCTask *task) {
														NSMutableDictionary* structuresDic = [NSMutableDictionary new];
														
														//														@synchronized(self.controller) {
														if (!self.controller.engine)
															return;
														eufe::ControlTower* controlTower = self.controller.engine->getControlTower();
														if (!controlTower)
															return;
														
														for (auto structure: controlTower->getStructures()) {
															NSInteger typeID = structure->getTypeID();
															NCFittingPOSStructuresViewControllerRow* row = structuresDic[@(typeID)];
															if (!row) {
																row = [NCFittingPOSStructuresViewControllerRow new];
																row.type = [self.controller typeWithItem:structure];
																structuresDic[@(typeID)] = row;
															}
															row.structures.push_back(structure);
														}
														
														totalPG = controlTower->getTotalPowerGrid();
														usedPG = controlTower->getPowerGridUsed();
														
														totalCPU = controlTower->getTotalCpu();
														usedCPU = controlTower->getCpuUsed();
														//														}
														
														rows = [[[structuresDic allValues] sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"type.typeName" ascending:YES]]] mutableCopy];
														
														if (self.activeAmountType) {
															NSInteger i = 1;
															for (NCFittingPOSStructuresViewControllerRow* row in rows) {
																if (row.type.typeID == self.activeAmountType.typeID) {
																	NCFittingPOSStructuresViewControllerPickerRow* pickerRow = [NCFittingPOSStructuresViewControllerPickerRow new];
																	pickerRow.associatedRow = row;
																	[rows insertObject:pickerRow atIndex:i];
																	break;
																}
																i++;
															}
														}
													}
										completionHandler:^(NCTask *task) {
											if (![task isCancelled]) {
												self.rows = rows;
												
												if (self.tableView.dataSource == self)
													[self.tableView reloadData];
												
//												self.tableHeaderView.powerGridLabel.text = [NSString stringWithTotalResources:totalPG usedResources:usedPG unit:@"MW"];
//												self.tableHeaderView.powerGridLabel.progress = totalPG > 0 ? usedPG / totalPG : 0;
//												self.tableHeaderView.cpuLabel.text = [NSString stringWithTotalResources:totalCPU usedResources:usedCPU unit:@"tf"];
//												self.tableHeaderView.cpuLabel.progress = usedCPU > 0 ? usedCPU / totalCPU : 0;
												
											}
										}];
}


#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return self.controller.engine ? 1 : 0;
	//return self.view.window ? 1 : 0;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return self.rows.count + 1;
}

#pragma mark -
#pragma mark Table view delegate

- (void) tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
	[super tableView:tableView willDisplayCell:cell forRowAtIndexPath:indexPath];
	if ([cell isKindOfClass:[NCFittingAmountCell class]]) {
		NCFittingPOSStructuresViewControllerPickerRow* pickerRow = self.rows[indexPath.row];
		NCFittingAmountCell* amountCell = (NCFittingAmountCell*) cell;
		amountCell.pickerView.dataSource = self;
		amountCell.pickerView.delegate = self;
		[amountCell.pickerView reloadAllComponents];
		[amountCell.pickerView selectRow:pickerRow.associatedRow.structures.size() - 1 inComponent:0 animated:NO];
	}
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	NSInteger i = 0;
	for (NCFittingPOSStructuresViewControllerPickerRow* row in self.rows) {
		if ([row isKindOfClass:[NCFittingPOSStructuresViewControllerPickerRow class]]) {
			self.activeAmountType = nil;
			NSMutableArray* rows = [self.rows mutableCopy];
			[rows removeObjectAtIndex:i];
			self.rows = rows;
			[tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:i inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
			if (indexPath.row == i - 1) {
				[tableView deselectRowAtIndexPath:indexPath animated:YES];
				return;
			}
			else if (indexPath.row > i)
				indexPath = [NSIndexPath indexPathForRow:indexPath.row - 1 inSection:indexPath.section];
			break;
		}
		i++;
	}
	
	UITableViewCell* cell = [tableView cellForRowAtIndexPath:indexPath];
	if (indexPath.row >= self.rows.count) {
		self.controller.typePickerViewController.title = NSLocalizedString(@"Structures", nil);
		
		[self.controller.typePickerViewController presentWithCategory:[NCDBEufeItemCategory categoryWithSlot:NCDBEufeItemSlotStructure size:0 race:nil]
													 inViewController:self.controller
															 fromRect:cell.bounds
															   inView:cell
															 animated:YES
													completionHandler:^(NCDBInvType *type) {
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
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - UIPickerViewDataSource

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
	return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
	return 50;
}

- (NSString*) pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
	return [NSString stringWithFormat:@"%ld", (long) row + 1];
}

- (void) pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)rowIndex inComponent:(NSInteger)component {
	int amount = (int) rowIndex + 1;
	NSInteger i = 0;
	for (NCFittingPOSStructuresViewControllerPickerRow* row in self.rows) {
		if ([row isKindOfClass:[NCFittingPOSStructuresViewControllerPickerRow class]]) {
			eufe::ControlTower* controlTower = self.controller.engine->getControlTower();
			eufe::TypeID typeID = row.associatedRow.structures.front()->getTypeID();
			
			if (row.associatedRow.structures.size() > amount) {
				int n = (int) row.associatedRow.structures.size() - amount;
				for (auto structure: row.associatedRow.structures) {
					if (n <= 0)
						break;
					controlTower->removeStructure(structure);
					n--;
				}
			}
			else {
				int n = amount - (int) row.associatedRow.structures.size();
				eufe::Structure* structure = row.associatedRow.structures.front();
				for (int i = 0; i < n; i++) {
					eufe::Structure* newStructure = controlTower->addStructure(structure->getTypeID());
					newStructure->setState(structure->getState());
				}
			}
			row.associatedRow.structures.clear();
			for (auto structure: controlTower->getStructures()) {
				if (structure->getTypeID() == typeID)
					row.associatedRow.structures.push_back(structure);
			}
			[self.controller reload];
		}
		i++;
	}
}

#pragma mark - Private

- (void) performActionForRowAtIndexPath:(NSIndexPath*) indexPath {
	UITableViewCell* cell = [self.tableView cellForRowAtIndexPath:indexPath];
	NCFittingPOSStructuresViewControllerRow* row = self.rows[indexPath.row];
	
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
		NSMutableArray* rows = [self.rows mutableCopy];
		[rows removeObjectAtIndex:indexPath.row];
		self.rows = rows;
		
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
		self.activeAmountType = row.type;
		NSMutableArray* rows = [self.rows mutableCopy];
		NCFittingPOSStructuresViewControllerPickerRow* pickerRow = [NCFittingPOSStructuresViewControllerPickerRow new];
		pickerRow.associatedRow = row;
		
		[rows insertObject:pickerRow atIndex:indexPath.row + 1];
		self.rows = rows;
		[self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:indexPath.row + 1 inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
	};
	
	void (^setAmmo)(eufe::StructuresList) = ^(eufe::StructuresList structures){
		self.controller.typePickerViewController.title = NSLocalizedString(@"Ammo", nil);
		
		[self.controller.typePickerViewController presentWithCategory:row.type.eufeItem.charge
													 inViewController:self.controller
															 fromRect:cell.bounds
															   inView:cell
															 animated:YES
													completionHandler:^(NCDBInvType *type) {
														for (auto structure: structures)
															structure->setCharge(type.typeID);
														[self.controller reload];
														[self.controller dismissAnimated];
													}];
	};
	
	void (^setAllModulesAmmo)(NSArray*) = ^(NSArray* structures){
		self.controller.typePickerViewController.title = NSLocalizedString(@"Ammo", nil);
		[self.controller.typePickerViewController presentWithCategory:row.type.eufeItem.charge
													 inViewController:self.controller
															 fromRect:cell.bounds
															   inView:cell
															 animated:YES
													completionHandler:^(NCDBInvType *type) {
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
	
	[[UIActionSheet actionSheetWithStyle:UIActionSheetStyleBlackTranslucent
								   title:nil
					   cancelButtonTitle:NSLocalizedString(@"Cancel", )
				  destructiveButtonTitle:ActionButtonDelete
					   otherButtonTitles:buttons
						 completionBlock:^(UIActionSheet *actionSheet, NSInteger selectedButtonIndex) {
							 [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
							 if (selectedButtonIndex != actionSheet.cancelButtonIndex) {
								 void (^block)(eufe::StructuresList) = actions[selectedButtonIndex];
								 block(row.structures);
							 }
						 } cancelBlock:nil] showFromRect:cell.bounds inView:cell animated:YES];
}

- (NSString*) tableView:(UITableView *)tableView cellIdentifierForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	if (indexPath.row >= self.rows.count)
		return @"Cell";
	else {
		NCFittingPOSStructuresViewControllerRow* row = self.rows[indexPath.row];
		if ([row isKindOfClass:[NCFittingPOSStructuresViewControllerPickerRow class]])
			return @"NCFittingAmountCell";
		else
			return @"NCFittingPOSStructureCell";
	}
}

- (void) tableView:(UITableView *)tableView configureCell:(UITableViewCell*) tableViewCell forRowAtIndexPath:(NSIndexPath*) indexPath {
	if (indexPath.row >= self.rows.count) {
		NCDefaultTableViewCell* cell = (NCDefaultTableViewCell*) tableViewCell;
		cell.iconView.image = [UIImage imageNamed:@"slotRig.png"];
		cell.titleLabel.text = NSLocalizedString(@"Add Structure", nil);
		cell.subtitleLabel.text = nil;
		cell.accessoryView = nil;
	}
	else {
		NCFittingPOSStructuresViewControllerRow* row = self.rows[indexPath.row];
		if (![row isKindOfClass:[NCFittingPOSStructuresViewControllerPickerRow class]]) {
			//			@synchronized(self.controller) {
			eufe::Structure* structure = row.structures.front();
			
			int optimal = (int) structure->getMaxRange();
			int falloff = (int) structure->getFalloff();
			float trackingSpeed = structure->getTrackingSpeed();
			
			NCFittingPOSStructureCell* cell = (NCFittingPOSStructureCell*) tableViewCell;
			
			cell.typeNameLabel.text = [NSString stringWithFormat:@"%@ (x%d)", row.type.typeName, (int) row.structures.size()];
			cell.typeImageView.image = row.type.icon ? row.type.icon.image.image : [[[NCDBEveIcon defaultTypeIcon] image] image];
			
			eufe::Charge* charge = structure->getCharge();
			
			if (charge) {
				NCDBInvType* type = [self.controller typeWithItem:charge];
				cell.chargeLabel.text = type.typeName;
			}
			else
				cell.chargeLabel.text = nil;
			
			
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
			//			}
		}
	}
}

@end
