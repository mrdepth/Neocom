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
#import "UIView+Nib.h"
#import "NCFittingAmountCell.h"

#define ActionButtonOffline NSLocalizedString(@"Put Offline", nil)
#define ActionButtonOnline NSLocalizedString(@"Put Online", nil)
#define ActionButtonActivate NSLocalizedString(@"Activate", nil)
#define ActionButtonDeactivate NSLocalizedString(@"Deactivate", nil)
#define ActionButtonAmmoCurrentStructure NSLocalizedString(@"Ammo (Current Structure)", nil)
#define ActionButtonAmmoAllStructures NSLocalizedString(@"Ammo (All Structures)", nil)
#define ActionButtonAmmo NSLocalizedString(@"Ammo", nil)
#define ActionButtonCancel NSLocalizedString(@"Cancel", nil)
#define ActionButtonDelete NSLocalizedString(@"Delete", nil)
#define ActionButtonChangeState NSLocalizedString(@"Change State", nil)
#define ActionButtonUnloadAmmo NSLocalizedString(@"Unload Ammo", nil)
#define ActionButtonShowStructureInfo NSLocalizedString(@"Show Structure Info", nil)
#define ActionButtonShowAmmoInfo NSLocalizedString(@"Show Ammo Info", nil)
#define ActionButtonAmount NSLocalizedString(@"Set Amount", nil)

@interface NCFittingPOSStructuresViewControllerRow : NSObject<NSCopying> {
	eufe::StructuresList _structures;
}
@property (nonatomic, assign) BOOL isUpToDate;

@property (nonatomic, readonly) eufe::StructuresList& structures;
@property (nonatomic, strong) NSString* typeName;
@property (nonatomic, strong) UIImage* typeImage;
@property (nonatomic, strong) NSString* chargeText;
@property (nonatomic, strong) NSString* optimalText;
@property (nonatomic, strong) UIImage* stateImage;
@property (nonatomic, strong) id sortKey;
@end

@implementation NCFittingPOSStructuresViewControllerRow

- (id) copyWithZone:(NSZone *)zone {
	NCFittingPOSStructuresViewControllerRow* other = [NCFittingPOSStructuresViewControllerRow new];
	other.isUpToDate = self.isUpToDate;
	other->_structures = _structures;
	other.typeName = self.typeName;
	other.typeImage = self.typeImage;
	other.chargeText = self.chargeText;
	other.optimalText = self.optimalText;
	other.stateImage = self.stateImage;
	other.sortKey = self.sortKey;
	return other;
}

@end

@interface NCFittingPOSStructuresViewController()
@property (nonatomic, strong) NSArray* rows;

- (void) performActionForRowAtIndexPath:(NSIndexPath*) indexPath;

@end

@implementation NCFittingPOSStructuresViewController

- (void) reloadWithCompletionBlock:(void (^)())completionBlock {
	if (self.controller.engine) {
		NSArray* oldRows = self.rows;
		
		[self.controller.engine performBlock:^{
			NSMutableDictionary* oldStructuresDic = [NSMutableDictionary new];
			for (NCFittingPOSStructuresViewControllerRow* row in oldRows)
				oldStructuresDic[@(row.structures.front()->getTypeID())] = row;

			NSMutableDictionary* structuresDic = [NSMutableDictionary new];
			auto controlTower = self.controller.engine.engine->getControlTower();
			
			for (auto structure: controlTower->getStructures()) {
				int32_t typeID = structure->getTypeID();
				NCFittingPOSStructuresViewControllerRow* row = structuresDic[@(typeID)];
				if (!row) {
					row = [oldStructuresDic[@(typeID)] copy] ?: [NCFittingPOSStructuresViewControllerRow new];
					row.sortKey = [NSString stringWithCString:structure->getTypeName() encoding:NSUTF8StringEncoding];
					row.isUpToDate = NO;
					row.structures.clear();
					structuresDic[@(typeID)] = row;
				}
				row.structures.push_back(structure);
			}
			
			/*float totalPG;
			float usedPG;
			float totalCPU;
			float usedCPU;

			totalPG = controlTower->getTotalPowerGrid();
			usedPG = controlTower->getPowerGridUsed();
			
			totalCPU = controlTower->getTotalCpu();
			usedCPU = controlTower->getCpuUsed();*/
			
			NSArray* rows = [[structuresDic allValues] sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"sortKey" ascending:YES]]];
			dispatch_async(dispatch_get_main_queue(), ^{
				self.rows = rows;
				completionBlock();
			});
		}];
		
	}
	else
		completionBlock();

}


#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return self.rows ? 1 : 0;
	//return self.view.window ? 1 : 0;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return self.rows.count + 1;
}

#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell* cell = [tableView cellForRowAtIndexPath:indexPath];
	if (indexPath.row >= self.rows.count) {
		self.controller.typePickerViewController.title = NSLocalizedString(@"Structures", nil);
		
		[self.controller.typePickerViewController presentWithCategory:[self.databaseManagedObjectContext categoryWithSlot:NCDBEufeItemSlotStructure size:0 race:nil]
													 inViewController:self.controller
															 fromRect:cell.bounds
															   inView:cell
															 animated:YES
													completionHandler:^(NCDBInvType *type) {
														int32_t typeID = type.typeID;
														[self.controller.engine performBlockAndWait:^{
															auto controlTower = self.controller.engine.engine->getControlTower();
															eufe::Module::State state = eufe::Module::STATE_ACTIVE;
															std::shared_ptr<eufe::Charge> charge = nullptr;
															for (auto structure: controlTower->getStructures()) {
																if (structure->getTypeID() == typeID) {
																	state = structure->getState();
																	charge = structure->getCharge();
																}
															}
															auto structure = controlTower->addStructure(typeID);
															structure->setState(state);
															if (charge)
																structure->setCharge(charge->getTypeID());
														}];
														[self.controller reload];
														[self.controller dismissAnimated];
													}];
	}
	else {
		[self performActionForRowAtIndexPath:indexPath];
	}
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - Private

- (void) performActionForRowAtIndexPath:(NSIndexPath*) indexPath {
	UITableViewCell* cell = [self.tableView cellForRowAtIndexPath:indexPath];
	NCFittingPOSStructuresViewControllerRow* row = self.rows[indexPath.row];
	
	NSMutableArray* actions = [NSMutableArray new];

	[self.controller.engine performBlockAndWait:^{
		auto controlTower = self.controller.engine.engine->getControlTower();
		auto structure = row.structures.front();
		auto structures = row.structures;
		NCDBInvType* type = [self.controller.engine.databaseManagedObjectContext invTypeWithTypeID:structure->getTypeID()];

		auto chargeGroups = structure->getChargeGroups();
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

		
		[actions addObject:[UIAlertAction actionWithTitle:ActionButtonDelete style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
			[self.controller.engine performBlockAndWait:^{
				for (auto structure: structures)
					controlTower->removeStructure(structure);
			}];
			[self.controller reload];
		}]];
		
		[actions addObject:[UIAlertAction actionWithTitle:ActionButtonShowStructureInfo style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
			[self.controller performSegueWithIdentifier:@"NCDatabaseTypeInfoViewController"
												 sender:@{@"sender": cell, @"object": [NCFittingEngineItemPointer pointerWithItem:structure]}];
		}]];
		
		
		if (structure->getCharge() != nullptr) {
			[actions addObject:[UIAlertAction actionWithTitle:ActionButtonShowAmmoInfo style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
				__block NCFittingEngineItemPointer* pointer;
				[self.controller.engine performBlockAndWait:^{
					pointer = [NCFittingEngineItemPointer pointerWithItem:structure->getCharge()];
				}];
				[self.controller performSegueWithIdentifier:@"NCDatabaseTypeInfoViewController"
													 sender:@{@"sender": cell, @"object": pointer}];
			}]];
		}

		
		if (structure->getState() >= eufe::Module::STATE_ACTIVE) {
			[actions addObject:[UIAlertAction actionWithTitle:ActionButtonOffline style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
				[self.controller.engine performBlockAndWait:^{
					for (auto structure: structures)
						structure->setState(eufe::Module::STATE_OFFLINE);
				}];
				[self.controller reload];
			}]];
		}
		else {
			[actions addObject:[UIAlertAction actionWithTitle:ActionButtonOnline style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
				[self.controller.engine performBlockAndWait:^{
					for (auto structure: structures)
						structure->setState(eufe::Module::STATE_ACTIVE);
				}];
				[self.controller reload];
			}]];
		}
		
		[actions addObject:[UIAlertAction actionWithTitle:ActionButtonAmount style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
			__block NSString* typeName;
			[self.controller.engine performBlockAndWait:^{
				typeName = type.typeName;
			}];
			UIAlertController* controller = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:NSLocalizedString(@"%@ amount", nil), typeName] message:nil preferredStyle:UIAlertControllerStyleAlert];
			__block UITextField* amountTextField;
			[controller addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
				amountTextField = textField;
				textField.keyboardType = UIKeyboardTypeNumberPad;
				textField.text = [NSString stringWithFormat:@"%d", (int) structures.size()];
				textField.clearButtonMode = UITextFieldViewModeAlways;
			}];
			[controller addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Ok", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
				int amount = [amountTextField.text intValue];
				if (amount > 0) {
					if (amount > 50)
						amount = 50;
					
					int n = (int) structures.size() - amount;
					[self.controller.engine performBlock:^{
						if (n > 0) {
							int i = n;
							for (auto structure: structures) {
								if (i <= 0)
									break;
								controlTower->removeStructure(structure);
								i--;
							}
						}
						else {
							auto charge = structure->getCharge();
							for (int i = n; i < 0; i++) {
								auto newStructure = controlTower->addStructure(structure->getTypeID());
								if (charge)
									newStructure->setCharge(charge->getTypeID());
							}
						}
						dispatch_async(dispatch_get_main_queue(), ^{
							[self.controller reload];
						});
					}];
				}
			}]];
			[controller addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
			}]];
			[self.controller presentViewController:controller animated:YES completion:nil];
		}]];
		
		if (chargeGroups.size() > 0) {
			UIAlertAction* (^ammoAction)(eufe::StructuresList, NSString*) = ^(eufe::StructuresList structures, NSString* title) {
				return [UIAlertAction actionWithTitle:title style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
					__block NSManagedObjectID* categoryID;
					[self.controller.engine performBlockAndWait:^{
						categoryID = [type.eufeItem.charge objectID];
					}];
					
					self.controller.typePickerViewController.title = NSLocalizedString(@"Ammo", nil);
					[self.controller.typePickerViewController presentWithCategory:[self.databaseManagedObjectContext existingObjectWithID:categoryID error:nil]
																 inViewController:self.controller
																		 fromRect:cell.bounds
																		   inView:cell
																		 animated:YES
																completionHandler:^(NCDBInvType *type) {
																	int32_t typeID = type.typeID;
																	[self.controller.engine performBlockAndWait:^{
																		for (auto structure: structures)
																			structure->setCharge(typeID);
																	}];
																	[self.controller reload];
																	[self.controller dismissAnimated];
																}];
				}];
			};
			[actions addObject:ammoAction(structures, ActionButtonAmmoCurrentStructure)];
			if (multiple)
				[actions addObject:ammoAction(controlTower->getStructures(), ActionButtonAmmoAllStructures)];
			if (structure->getCharge() != nil) {
				[actions addObject:ammoAction(structures, ActionButtonAmmoCurrentStructure)];

				[actions addObject:[UIAlertAction actionWithTitle:ActionButtonUnloadAmmo style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
					[self.controller.engine performBlockAndWait:^{
						for (auto structure: structures)
							structure->clearCharge();
					}];
					[self.controller reload];
				}]];
			}
		}
	}];
	
	
	UIAlertController* controller = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
	for (UIAlertAction* action in actions)
		[controller addAction:action];
	[controller addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {}]];
	[self.controller presentViewController:controller animated:YES completion:nil];
}

- (NSString*) tableView:(UITableView *)tableView cellIdentifierForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	if (indexPath.row >= self.rows.count)
		return @"Cell";
	else
		return @"NCFittingPOSStructureCell";
}

- (void) tableView:(UITableView *)tableView configureCell:(UITableViewCell*) tableViewCell forRowAtIndexPath:(NSIndexPath*) indexPath {
	NCFittingPOSStructuresViewControllerRow* row = indexPath.row < self.rows.count ? self.rows[indexPath.row] : nil;

	if (indexPath.row >= self.rows.count) {
		NCDefaultTableViewCell* cell = (NCDefaultTableViewCell*) tableViewCell;
		cell.iconView.image = [UIImage imageNamed:@"slotRig.png"];
		cell.titleLabel.text = NSLocalizedString(@"Add Structure", nil);
		cell.subtitleLabel.text = nil;
		cell.accessoryView = nil;
	}
	else {
		NCFittingPOSStructureCell* cell = (NCFittingPOSStructureCell*) tableViewCell;
		
		cell.typeNameLabel.text = row.typeName;
		cell.typeImageView.image = row.typeImage;
		cell.chargeLabel.text = row.chargeText;
		cell.optimalLabel.text = row.optimalText;
		cell.stateImageView.image = row.stateImage;
	}
	if (row && !row.isUpToDate) {
		row.isUpToDate = YES;
		[self.controller.engine performBlock:^{
			auto structure = row.structures.front();
			int optimal = (int) structure->getMaxRange();
			int falloff = (int) structure->getFalloff();
			float trackingSpeed = structure->getTrackingSpeed();
			
			NCDBInvType* type = [self.controller.engine.databaseManagedObjectContext invTypeWithTypeID:structure->getTypeID()];
			
			row.typeName = [NSString stringWithFormat:@"%@ (x%d)", type.typeName, (int) row.structures.size()];
			row.typeImage = type.icon.image.image;
			
			auto charge = structure->getCharge();
			if (charge)
				row.chargeText = type.typeName;
			else
				row.chargeText = nil;

			if (optimal > 0) {
				NSString *s = [NSString stringWithFormat:NSLocalizedString(@"%@m", nil), [NSNumberFormatter neocomLocalizedStringFromNumber:@(optimal)]];
				if (falloff > 0)
					s = [s stringByAppendingFormat:NSLocalizedString(@" + %@m", nil), [NSNumberFormatter neocomLocalizedStringFromNumber:@(falloff)]];
				if (trackingSpeed > 0)
					s = [s stringByAppendingFormat:NSLocalizedString(@" (%@ rad/sec)", nil), [NSNumberFormatter neocomLocalizedStringFromNumber:@(trackingSpeed)]];
				row.optimalText = s;
			}
			else
				row.optimalText = nil;

			switch (structure->getState()) {
				case eufe::Module::STATE_ACTIVE:
					row.stateImage = [UIImage imageNamed:@"active.png"];
					break;
				case eufe::Module::STATE_ONLINE:
					row.stateImage = [UIImage imageNamed:@"online.png"];
					break;
				case eufe::Module::STATE_OVERLOADED:
					row.stateImage = [UIImage imageNamed:@"overheated.png"];
					break;
				default:
					row.stateImage = [UIImage imageNamed:@"offline.png"];
					break;
			}

			dispatch_async(dispatch_get_main_queue(), ^{
				[self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
			});
		}];
	}
}

@end
