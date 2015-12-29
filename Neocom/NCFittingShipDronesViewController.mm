//
//  NCFittingShipDronesViewController.m
//  Neocom
//
//  Created by Артем Шиманский on 12.06.15.
//  Copyright (c) 2015 Artem Shimanski. All rights reserved.
//

#import "NCFittingShipDronesViewController.h"
#import "NCFittingShipViewController.h"
#import "NCFittingShipDroneCell.h"
#import "NCTableViewCell.h"
#import "NSNumberFormatter+Neocom.h"
#import "UIView+Nib.h"
#import "NSString+Neocom.h"
#import "NCFittingAmountCell.h"

#define ActionButtonActivate NSLocalizedString(@"Activate", nil)
#define ActionButtonDeactivate NSLocalizedString(@"Deactivate", nil)
#define ActionButtonAmount NSLocalizedString(@"Set Amount", nil)
#define ActionButtonCancel NSLocalizedString(@"Cancel", nil)
#define ActionButtonDelete NSLocalizedString(@"Delete", nil)
#define ActionButtonShowInfo NSLocalizedString(@"Show Info", nil)
#define ActionButtonSetTarget NSLocalizedString(@"Set Target", nil)
#define ActionButtonClearTarget NSLocalizedString(@"Clear Target", nil)
#define ActionButtonAffectingSkills NSLocalizedString(@"Affecting Skills", nil)

@interface NCFittingShipDronesViewControllerRow : NSObject<NSCopying> {
	eufe::DronesList _drones;
}
@property (nonatomic, assign) BOOL isUpToDate;

@property (nonatomic, readonly) eufe::DronesList& drones;
@property (nonatomic, strong) NSString* typeName;
@property (nonatomic, strong) UIImage* typeImage;
@property (nonatomic, strong) NSString* optimalText;
@property (nonatomic, assign) BOOL hasTarget;
@property (nonatomic, strong) UIImage* stateImage;
@property (nonatomic, strong) id sortKey;
@end

@implementation NCFittingShipDronesViewControllerRow

- (id) copyWithZone:(NSZone *)zone {
	NCFittingShipDronesViewControllerRow* other = [NCFittingShipDronesViewControllerRow new];
	other.isUpToDate = self.isUpToDate;
	other->_drones = _drones;
	other.typeName = self.typeName;
	other.typeImage = self.typeImage;
	other.optimalText = self.optimalText;
	other.hasTarget = self.hasTarget;
	other.stateImage = self.stateImage;
	other.sortKey = self.sortKey;
	return other;
}

@end

@interface NCFittingShipDronesViewController()
@property (nonatomic, strong) NSArray* rows;

- (void) performActionForRowAtIndexPath:(NSIndexPath*) indexPath;

@end

@implementation NCFittingShipDronesViewController

- (void) viewDidLoad {
	[super viewDidLoad];
}

- (void) reloadWithCompletionBlock:(void (^)())completionBlock {
	auto pilot = self.controller.fit.pilot;
	if (pilot) {
		NSArray* oldRows = self.rows;
		
		[self.controller.engine performBlock:^{
			NSMutableDictionary* oldDronesDic = [NSMutableDictionary new];
			for (NCFittingShipDronesViewControllerRow* row in oldRows)
				oldDronesDic[@(row.drones.front()->getTypeID())] = row;
			
			
			NSMutableDictionary* dronesDic = [NSMutableDictionary new];
			auto ship = self.controller.fit.pilot->getShip();
			for (const auto& drone: ship->getDrones()) {
				int32_t typeID = drone->getTypeID();
				NCFittingShipDronesViewControllerRow* row = dronesDic[@(typeID)];
				if (!row) {
					row = [oldDronesDic[@(typeID)] copy] ?: [NCFittingShipDronesViewControllerRow new];
					row.sortKey = [NSString stringWithCString:drone->getTypeName() encoding:NSUTF8StringEncoding];
					row.isUpToDate = NO;
					row.drones.clear();
					dronesDic[@(typeID)] = row;
				}
				row.drones.push_back(drone);
			}
			
			NSArray* rows = [[dronesDic allValues] sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"sortKey" ascending:YES]]];
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
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return self.rows.count + 1;
}



#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell* cell = [tableView cellForRowAtIndexPath:indexPath];
	if (indexPath.row >= self.rows.count) {
		self.controller.typePickerViewController.title = NSLocalizedString(@"Drones", nil);
		
		[self.controller.typePickerViewController presentWithCategory:[self.databaseManagedObjectContext categoryWithSlot:NCDBEufeItemSlotDrone size:0 race:nil]
													 inViewController:self.controller
															 fromRect:cell.bounds
															   inView:cell
															 animated:YES
													completionHandler:^(NCDBInvType *type) {
														eufe::TypeID typeID = type.typeID;
														[self.controller.engine performBlockAndWait:^{
															auto ship = self.controller.fit.pilot->getShip();
															
															std::shared_ptr<eufe::Drone> sameDrone = nullptr;
															for (const auto& i: ship->getDrones()) {
																if (i->getTypeID() == typeID) {
																	sameDrone = i;
																	break;
																}
															}
															int dronesLeft = std::max(ship->getMaxActiveDrones(), 1);
															self.controller.engine.engine->beginUpdates();
															for (;dronesLeft > 0; dronesLeft--) {
																auto drone = ship->addDrone(typeID);
																if (sameDrone) {
																	drone->setTarget(sameDrone->getTarget());
																	drone->setActive(sameDrone->isActive());
																}
															}
															self.controller.engine.engine->commitUpdates();
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

- (NSString*)tableView:(UITableView *)tableView cellIdentifierForRowAtIndexPath:(NSIndexPath *)indexPath {
	NCFittingShipDronesViewControllerRow* row = indexPath.row < self.rows.count ? self.rows[indexPath.row] : nil;
	if (!row.typeName)
		return @"Cell";
	else
		return @"NCFittingShipDroneCell";
}

- (void) tableView:(UITableView *)tableView configureCell:(UITableViewCell*) tableViewCell forRowAtIndexPath:(NSIndexPath*) indexPath {
	NCFittingShipDronesViewControllerRow* row = indexPath.row < self.rows.count ? self.rows[indexPath.row] : nil;

	if (!row.typeName) {
		NCDefaultTableViewCell* cell = (NCDefaultTableViewCell*) tableViewCell;
		if (indexPath.row >= self.rows.count) {
			cell.iconView.image = [UIImage imageNamed:@"drone"];
			cell.titleLabel.text = NSLocalizedString(@"Add Drone", nil);
		}
		else {
			cell.iconView.image = nil;
			cell.titleLabel.text = nil;
		}
		cell.subtitleLabel.text = nil;
		cell.accessoryView = nil;
	}
	else {
		NCFittingShipDroneCell* cell = (NCFittingShipDroneCell*) tableViewCell;
		
		cell.typeNameLabel.text = row.typeName;
		cell.typeImageView.image = row.typeImage ?: self.defaultTypeImage;
		cell.optimalLabel.text = row.optimalText;
		cell.stateImageView.image = row.stateImage;
		cell.targetImageView.image = row.hasTarget ? self.targetImage : nil;
	}
	if (row && !row.isUpToDate) {
		row.isUpToDate = YES;
		[self.controller.engine performBlock:^{
			NCFittingShipDronesViewControllerRow* newRow = [NCFittingShipDronesViewControllerRow new];
			auto drone = row.drones.front();
			int optimal = (int) drone->getMaxRange();
			int falloff = (int) drone->getFalloff();
			float trackingSpeed = drone->getTrackingSpeed();
			
			NCDBInvType* type = [self.controller.engine.databaseManagedObjectContext invTypeWithTypeID:drone->getTypeID()];
			newRow.typeName = [NSString stringWithFormat:@"%@ (x%d)", type.typeName, (int) row.drones.size()];
			newRow.typeImage = type.icon.image.image;
			
			if (optimal > 0) {
				NSString *s = [NSString stringWithFormat:NSLocalizedString(@"%@m", nil), [NSNumberFormatter neocomLocalizedStringFromNumber:@(optimal)]];
				if (falloff > 0)
					s = [s stringByAppendingFormat:NSLocalizedString(@" + %@m", nil), [NSNumberFormatter neocomLocalizedStringFromNumber:@(falloff)]];
				if (trackingSpeed > 0)
					s = [s stringByAppendingFormat:NSLocalizedString(@" (%@ rad/sec)", nil), [NSNumberFormatter neocomLocalizedStringFromNumber:@(trackingSpeed)]];
				newRow.optimalText = s;
			}
			else
				newRow.optimalText = nil;
			
			newRow.stateImage = drone->isActive() ? [UIImage imageNamed:@"active"] : [UIImage imageNamed:@"offline"];
			newRow.hasTarget = drone->getTarget() != nullptr;

			dispatch_async(dispatch_get_main_queue(), ^{
				row.typeName = newRow.typeName;
				row.typeImage = newRow.typeImage;
				row.optimalText = newRow.optimalText;
				row.hasTarget = newRow.hasTarget;
				row.stateImage = newRow.stateImage;
				[self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
			});
		}];
	}
}


#pragma mark - Private

- (void) performActionForRowAtIndexPath:(NSIndexPath*) indexPath {
	UITableViewCell* cell = [self.tableView cellForRowAtIndexPath:indexPath];
	NCFittingShipDronesViewControllerRow* row = self.rows[indexPath.row];
	NSMutableArray* actions = [NSMutableArray new];

	[self.controller.engine performBlockAndWait:^{
		auto ship = self.controller.fit.pilot->getShip();
		auto drone = row.drones.front();
		auto drones = row.drones;
		NCDBInvType* type = [self.controller.engine.databaseManagedObjectContext invTypeWithTypeID:drone->getTypeID()];
		
		[actions addObject:[UIAlertAction actionWithTitle:ActionButtonDelete style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
			[self.controller.engine performBlockAndWait:^{
				self.controller.engine.engine->beginUpdates();
				for (const auto& drone: drones)
					ship->removeDrone(drone);
				self.controller.engine.engine->commitUpdates();
			}];
			[self.controller reload];
		}]];

		[actions addObject:[UIAlertAction actionWithTitle:ActionButtonShowInfo style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
			[self.controller performSegueWithIdentifier:@"NCDatabaseTypeInfoViewController"
												 sender:@{@"sender": cell, @"object": [NCFittingEngineItemPointer pointerWithItem:drone]}];
		}]];

		
		if (drone->isActive()) {
			[actions addObject:[UIAlertAction actionWithTitle:ActionButtonDeactivate style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
				[self.controller.engine performBlockAndWait:^{
					self.controller.engine.engine->beginUpdates();
					for (const auto& drone: drones)
						drone->setActive(false);
					self.controller.engine.engine->commitUpdates();
				}];
				[self.controller reload];
			}]];
		}
		else {
			[actions addObject:[UIAlertAction actionWithTitle:ActionButtonActivate style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
				[self.controller.engine performBlockAndWait:^{
					self.controller.engine.engine->beginUpdates();
					for (const auto& drone: drones)
						drone->setActive(true);
					self.controller.engine.engine->commitUpdates();
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
				textField.text = [NSString stringWithFormat:@"%d", (int) drones.size()];
				textField.clearButtonMode = UITextFieldViewModeAlways;
			}];
			[controller addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Ok", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
				int amount = [amountTextField.text intValue];
				if (amount > 0) {
					if (amount > 50)
						amount = 50;
					
					int n = (int) drones.size() - amount;
					[self.controller.engine performBlock:^{
						self.controller.engine.engine->beginUpdates();
						if (n > 0) {
							int i = n;
							for (const auto& drone: drones) {
								if (i <= 0)
									break;
								ship->removeDrone(drone);
								i--;
							}
						}
						else {
							auto drone = drones.front();
							for (int i = n; i < 0; i++) {
								auto newDrone = ship->addDrone(drone->getTypeID());
								newDrone->setActive(drone->isActive());
								newDrone->setTarget(drone->getTarget());
							}
						}
						self.controller.engine.engine->commitUpdates();
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

		[actions addObject:[UIAlertAction actionWithTitle:ActionButtonAffectingSkills style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
			[self.controller performSegueWithIdentifier:@"NCFittingShipAffectingSkillsViewController"
												 sender:@{@"sender": cell, @"object": @[[NCFittingEngineItemPointer pointerWithItem:drone]]}];
		}]];

		if (self.controller.fits.count > 1) {
			[actions addObject:[UIAlertAction actionWithTitle:ActionButtonSetTarget style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
				NSMutableArray* array = [NSMutableArray new];
				[self.controller.engine performBlockAndWait:^{
					self.controller.engine.engine->beginUpdates();
					for (const auto& drone: drones)
						[array addObject:[NCFittingEngineItemPointer pointerWithItem:drone]];
					self.controller.engine.engine->commitUpdates();
				}];
				[self.controller performSegueWithIdentifier:@"NCFittingTargetsViewController"
													 sender:@{@"sender": cell, @"object": array}];
			}]];
			if (drone->getTarget() != NULL) {
				[actions addObject:[UIAlertAction actionWithTitle:ActionButtonClearTarget style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
					[self.controller.engine performBlockAndWait:^{
						self.controller.engine.engine->beginUpdates();
						for (const auto& drone: drones)
							drone->clearTarget();
						self.controller.engine.engine->commitUpdates();
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

	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		controller.modalPresentationStyle = UIModalPresentationPopover;
		[self presentViewController:controller animated:YES completion:nil];
		UITableViewCell* sender = cell;
		controller.popoverPresentationController.sourceView = sender;
		controller.popoverPresentationController.sourceRect = [sender bounds];
	}
	else
		[self presentViewController:controller animated:YES completion:nil];

}

@end
