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
#import "NCFittingSectionGenericHeaderView.h"

#define ActionButtonActivate NSLocalizedString(@"Activate", nil)
#define ActionButtonDeactivate NSLocalizedString(@"Deactivate", nil)
#define ActionButtonAmount NSLocalizedString(@"Set Amount", nil)
#define ActionButtonCancel NSLocalizedString(@"Cancel", nil)
#define ActionButtonDelete NSLocalizedString(@"Delete", nil)
#define ActionButtonShowInfo NSLocalizedString(@"Show Info", nil)
#define ActionButtonSetTarget NSLocalizedString(@"Set Target", nil)
#define ActionButtonClearTarget NSLocalizedString(@"Clear Target", nil)
#define ActionButtonAffectingSkills NSLocalizedString(@"Affecting Skills", nil)

@interface NCFittingShipDronesViewControllerSection : NSObject
@property (nonatomic, strong) NSArray* rows;
@property (nonatomic, assign) dgmpp::Drone::FighterSquadron squadron;
@property (nonatomic, assign) int numberOfSlots;
@property (nonatomic, assign) int activeDrones;
@end

@implementation NCFittingShipDronesViewControllerSection
@end

@interface NCFittingShipDronesViewControllerRow : NSObject<NSCopying> {
	dgmpp::DronesList _drones;
}
@property (nonatomic, assign) BOOL isUpToDate;

@property (nonatomic, readonly) dgmpp::DronesList& drones;
@property (nonatomic, strong) NSString* typeName;
@property (nonatomic, strong) UIImage* typeImage;
@property (nonatomic, strong) NSString* optimalText;
@property (nonatomic, assign) BOOL hasTarget;
@property (nonatomic, assign) BOOL active;
@property (nonatomic, assign) dgmpp::TypeID typeID;
@property (nonatomic, assign) std::shared_ptr<dgmpp::Ship> target;
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
	other.active = self.active;
	other.typeID = self.typeID;
	other.target = self.target;
	return other;
}

@end

@interface NCFittingShipDronesViewController()
@property (nonatomic, strong) NSArray* sections;

- (void) performActionForRowAtIndexPath:(NSIndexPath*) indexPath;

@end

@implementation NCFittingShipDronesViewController

- (void) viewDidLoad {
	[super viewDidLoad];
}

- (void) reloadWithCompletionBlock:(void (^)())completionBlock {
	auto pilot = self.controller.fit.pilot;
	if (pilot) {
		NSMutableArray* sections = [NSMutableArray new];
		NSArray* oldSections = self.sections;

		[self.controller.engine performBlock:^{
			NSMutableArray* oldDrones = [NSMutableArray new];
			for (NCFittingShipDronesViewControllerSection* section in oldSections)
				for (NCFittingShipDronesViewControllerRow* row in section.rows)
					[oldDrones addObject:row];
			
			
			auto ship = self.controller.fit.pilot->getShip();
			
			NCFittingShipDronesViewControllerRow* (^findRow)(std::shared_ptr<dgmpp::Drone>&, NSArray*, BOOL) = ^(std::shared_ptr<dgmpp::Drone>& drone, NSArray* rows, BOOL requireFreeSpace) {
				BOOL active = drone->isActive();
				dgmpp::TypeID typeID = drone->getTypeID();
				auto target = drone->getTarget();
				int squadronSize = drone->getSquadronSize() ?: 5;
				for (NCFittingShipDronesViewControllerRow* row in rows) {
					if (row.active == active && row.typeID == typeID && row.target == target && (!requireFreeSpace || (requireFreeSpace && row.drones.size() < squadronSize)))
						return row;
				}
				return (NCFittingShipDronesViewControllerRow*) nil;
			};
			
			
			NSMutableDictionary* squadrons = [NSMutableDictionary new];
			for (auto drone: ship->getDrones()) {
				NSMutableArray* drones = squadrons[@(drone->getSquadron())];
				if (!drones)
					squadrons[@(drone->getSquadron())] = drones = [NSMutableArray new];

				NCFittingShipDronesViewControllerRow* row = findRow(drone, drones, YES);
				if (!row) {
					row = findRow(drone, oldDrones, NO);
					if (row)
						[oldDrones removeObject:row];
					else {
						row = [NCFittingShipDronesViewControllerRow new];
						row.active = drone->isActive();
						row.typeID = drone->getTypeID();
						row.target = drone->getTarget();
						row.sortKey = [NSString stringWithCString:drone->getTypeName() encoding:NSUTF8StringEncoding];
					}
					row.isUpToDate = NO;
					row.drones.clear();
					[drones addObject:row];
				}
				row.drones.push_back(drone);
			}
			
			if (ship->getTotalDroneBay() > 0 || ship->getDroneBayUsed() > 0 || squadrons[@(dgmpp::Drone::FIGHTER_SQUADRON_NONE)]) {
				NSArray* drones = squadrons[@(dgmpp::Drone::FIGHTER_SQUADRON_NONE)];
				NCFittingShipDronesViewControllerSection* section = [NCFittingShipDronesViewControllerSection new];
				section.rows = [drones sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"sortKey" ascending:YES]]];
				section.squadron = dgmpp::Drone::FIGHTER_SQUADRON_NONE;
				section.numberOfSlots = -1;
				[sections addObject:section];
			}
	
			for (auto squadron: {dgmpp::Drone::FIGHTER_SQUADRON_HEAVY, dgmpp::Drone::FIGHTER_SQUADRON_LIGHT, dgmpp::Drone::FIGHTER_SQUADRON_SUPPORT}) {
				NSArray* drones = squadrons[@(squadron)];
				if (ship->getDroneSquadronLimit(squadron) > 0 || drones) {
					NCFittingShipDronesViewControllerSection* section = [NCFittingShipDronesViewControllerSection new];
					section.rows = [drones sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"sortKey" ascending:YES]]];
					section.squadron = squadron;
					section.numberOfSlots = ship->getDroneSquadronLimit(squadron);
					
					std::map<int,std::pair<int, int>> squadrons;
					for (NCFittingShipDronesViewControllerRow* row in section.rows)
						for (const auto& drone: row.drones)
							if (drone->isActive())
								squadrons[drone->getTypeID()] = std::make_pair(squadrons[drone->getTypeID()].first + 1, drone->getSquadronSize());
					int n = 0;
					for (const auto i: squadrons)
						n += ceil((double) i.second.first / (double) i.second.second);
					section.activeDrones = n;
					[sections addObject:section];
				}
			}

			dispatch_async(dispatch_get_main_queue(), ^{
				self.sections = sections;
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
	return self.sections ? self.sections.count + 1 : 0;
}


- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)sectionIndex {
	if (sectionIndex == self.sections.count)
		return 1;
	else {
		NCFittingShipDronesViewControllerSection* section = self.sections[sectionIndex];
		return section.rows.count;
	}
}



#pragma mark -
#pragma mark Table view delegate

- (UIView*) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)sectionIndex {
	if (sectionIndex == self.sections.count) {
		UIView* view = [[UIView alloc] initWithFrame:CGRectZero];
		view.backgroundColor = [UIColor clearColor];
		return view;
	}
	else {
		NCFittingShipDronesViewControllerSection* section = self.sections[sectionIndex];
		if (section.squadron == dgmpp::Drone::FIGHTER_SQUADRON_NONE) {
			UIView* view = [[UIView alloc] initWithFrame:CGRectZero];
			view.backgroundColor = [UIColor clearColor];
			return view;
		}
		else {
			NCFittingSectionGenericHeaderView* header = [tableView dequeueReusableHeaderFooterViewWithIdentifier:@"NCFittingSectionGenericHeaderView"];
			if (section.squadron == dgmpp::Drone::FIGHTER_SQUADRON_HEAVY) {
				header.imageView.image = [UIImage imageNamed:@"drone"];
				header.titleLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Heavy Fighter Squadrons %d/%d", nil), section.activeDrones, section.numberOfSlots];
			}
			else if (section.squadron == dgmpp::Drone::FIGHTER_SQUADRON_LIGHT) {
				header.imageView.image = [UIImage imageNamed:@"drone"];
				header.titleLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Light Fighter Squadrons %d/%d", nil), section.activeDrones, section.numberOfSlots];
			}
			else if (section.squadron == dgmpp::Drone::FIGHTER_SQUADRON_SUPPORT) {
				header.imageView.image = [UIImage imageNamed:@"drone"];
				header.titleLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Support Fighter Squadrons %d/%d", nil), section.activeDrones, section.numberOfSlots];
			}
			return header;
		}
	}
	return nil;
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)sectionIndex {
	if (sectionIndex == self.sections.count)
		return 0;
	else {
		NCFittingShipDronesViewControllerSection* section = self.sections[sectionIndex];
		if (section.squadron == dgmpp::Drone::FIGHTER_SQUADRON_NONE)
			return 0;
		else
			return 44;
	}
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell* cell = [tableView cellForRowAtIndexPath:indexPath];
	if (indexPath.section == self.sections.count) {
		self.controller.typePickerViewController.title = NSLocalizedString(@"Drones", nil);
		
		__block dgmpp::TypeID categoryID = 0;
		[self.controller.engine performBlockAndWait:^{
			auto ship = self.controller.fit.pilot->getShip();
			if (ship->getTotalFighterHangar() > 0)
				categoryID = dgmpp::FIGHTER_CATEGORY_ID;
			else
				categoryID = dgmpp::DRONE_CATEGORY_ID;
		}];

		[self.controller.typePickerViewController presentWithCategory:[self.databaseManagedObjectContext categoryWithSlot:NCDBDgmppItemSlotDrone size:categoryID race:nil]
													 inViewController:self.controller
															 fromRect:cell.bounds
															   inView:cell
															 animated:YES
													completionHandler:^(NCDBInvType *type) {
														dgmpp::TypeID typeID = type.typeID;
														[self.controller.engine performBlockAndWait:^{
															auto ship = self.controller.fit.pilot->getShip();
															
															self.controller.engine.engine->beginUpdates();
															auto drone = ship->addDrone(typeID);
															int squadronSize = drone->getSquadronSize() ?: 5;
															for (int i = 1; i < squadronSize; i++) {
																auto drone = ship->addDrone(typeID);
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
	if (indexPath.section == self.sections.count)
		return @"Cell";
	else
		return @"NCFittingShipDroneCell";
	/*NCFittingShipDronesViewControllerRow* row = indexPath.row < self.rows.count ? self.rows[indexPath.row] : nil;
	if (!row.typeName)
		return @"Cell";
	else
		return @"NCFittingShipDroneCell";*/
}

- (void) tableView:(UITableView *)tableView configureCell:(UITableViewCell*) tableViewCell forRowAtIndexPath:(NSIndexPath*) indexPath {
	if (indexPath.section == self.sections.count) {
		NCDefaultTableViewCell* cell = (NCDefaultTableViewCell*) tableViewCell;
		cell.iconView.image = [UIImage imageNamed:@"drone"];
		cell.titleLabel.text = NSLocalizedString(@"Add Drone", nil);
		cell.subtitleLabel.text = nil;
		cell.accessoryView = nil;
	}
	else {
		NCFittingShipDronesViewControllerSection* section = self.sections[indexPath.section];
		NCFittingShipDronesViewControllerRow* row = section.rows[indexPath.row];
		NCFittingShipDroneCell* cell = (NCFittingShipDroneCell*) tableViewCell;
		
		cell.typeNameLabel.text = row.typeName;
		cell.typeImageView.image = row.typeImage ?: self.defaultTypeImage;
		cell.optimalLabel.text = row.optimalText;
		cell.stateImageView.image = row.stateImage;
		cell.targetImageView.image = row.hasTarget ? self.targetImage : nil;
		
		if (row && !row.isUpToDate) {
			row.isUpToDate = YES;
			[self.controller.engine performBlock:^{
				NCFittingShipDronesViewControllerRow* newRow = [NCFittingShipDronesViewControllerRow new];
				auto drone = row.drones.front();
				int optimal = (int) drone->getMaxRange();
				int falloff = (int) drone->getFalloff();
				float trackingSpeed = drone->getTrackingSpeed();
				
				NCDBInvType* type = [self.controller.engine.databaseManagedObjectContext invTypeWithTypeID:drone->getTypeID()];
				if (section.squadron == dgmpp::Drone::FIGHTER_SQUADRON_NONE)
					newRow.typeName = [NSString stringWithFormat:@"%@ (x%d)", type.typeName, (int) row.drones.size()];
				else
					newRow.typeName = [NSString stringWithFormat:NSLocalizedString(@"%@ (%d/%d)", nil), type.typeName, (int) row.drones.size() , (int) drone->getSquadronSize()];
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
}


#pragma mark - Private

- (void) performActionForRowAtIndexPath:(NSIndexPath*) indexPath {
	UITableViewCell* cell = [self.tableView cellForRowAtIndexPath:indexPath];
	NCFittingShipDronesViewControllerSection* section = self.sections[indexPath.section];
	NCFittingShipDronesViewControllerRow* row = section.rows[indexPath.row];
	NSMutableArray* actions = [NSMutableArray new];

	[self.controller.engine performBlockAndWait:^{
		auto ship = self.controller.fit.pilot->getShip();
		auto drone = row.drones.front();
		auto drones = row.drones;
		NCDBInvType* type = [self.controller.engine.databaseManagedObjectContext invTypeWithTypeID:drone->getTypeID()];
		int squadronSize = drone->getSquadronSize();
		if (squadronSize == 0)
			squadronSize = 1;
		
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
