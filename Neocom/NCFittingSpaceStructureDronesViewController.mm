//
//  NCFittingSpaceStructureDronesViewController.m
//  Neocom
//
//  Created by Артем Шиманский on 14.03.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCFittingSpaceStructureDronesViewController.h"
#import "NCFittingSpaceStructureViewController.h"
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

@interface NCFittingSpaceStructureDronesViewControllerSection : NSObject
@property (nonatomic, strong) NSArray* rows;
@property (nonatomic, assign) dgmpp::Drone::FighterSquadron squadron;
@property (nonatomic, assign) int numberOfSlots;
@property (nonatomic, assign) int activeDrones;
@end

@implementation NCFittingSpaceStructureDronesViewControllerSection
@end

@interface NCFittingSpaceStructureDronesViewControllerRow : NSObject<NSCopying> {
	dgmpp::DronesList _drones;
}
@property (nonatomic, assign) BOOL isUpToDate;

@property (nonatomic, readonly) dgmpp::DronesList& drones;
@property (nonatomic, strong) NSString* typeName;
@property (nonatomic, strong) UIImage* typeImage;
@property (nonatomic, strong) NSString* optimalText;
@property (nonatomic, assign) BOOL hasTarget;
@property (nonatomic, strong) UIImage* stateImage;
@property (nonatomic, strong) id sortKey;
@end

@implementation NCFittingSpaceStructureDronesViewControllerRow

- (id) copyWithZone:(NSZone *)zone {
	NCFittingSpaceStructureDronesViewControllerRow* other = [NCFittingSpaceStructureDronesViewControllerRow new];
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

@interface NCFittingSpaceStructureDronesViewController()
@property (nonatomic, strong) NSArray* sections;

- (void) performActionForRowAtIndexPath:(NSIndexPath*) indexPath;

@end

@implementation NCFittingSpaceStructureDronesViewController

- (void) viewDidLoad {
	[super viewDidLoad];
}

- (void) reloadWithCompletionBlock:(void (^)())completionBlock {
	auto pilot = self.controller.fit.pilot;
	if (pilot) {
		NSMutableArray* sections = [NSMutableArray new];
		NSArray* oldSections = self.sections;
		
		[self.controller.engine performBlock:^{
			NSMutableDictionary* oldDronesDic = [NSMutableDictionary new];
			for (NCFittingSpaceStructureDronesViewControllerSection* section in oldSections)
				for (NCFittingSpaceStructureDronesViewControllerRow* row in section.rows)
					oldDronesDic[@(row.drones.front()->getTypeID())] = row;
			
			
			auto structure = self.controller.fit.pilot->getSpaceStructure();
			
			NSMutableDictionary* squadrons = [NSMutableDictionary new];
			for (const auto& drone: structure->getDrones()) {
				NSMutableDictionary* dronesDic = squadrons[@(drone->getSquadron())];
				if (!dronesDic)
					squadrons[@(drone->getSquadron())] = dronesDic = [NSMutableDictionary new];
				
				int32_t typeID = drone->getTypeID();
				NCFittingSpaceStructureDronesViewControllerRow* row = dronesDic[@(typeID)];
				if (!row) {
					row = [oldDronesDic[@(typeID)] copy] ?: [NCFittingSpaceStructureDronesViewControllerRow new];
					row.sortKey = [NSString stringWithCString:drone->getTypeName() encoding:NSUTF8StringEncoding];
					row.isUpToDate = NO;
					row.drones.clear();
					dronesDic[@(typeID)] = row;
				}
				row.drones.push_back(drone);
			}
			
			if (structure->getTotalDroneBay() > 0 || structure->getDroneBayUsed() > 0 || squadrons[@(dgmpp::Drone::FIGHTER_SQUADRON_NONE)]) {
				NSDictionary* dronesDic = squadrons[@(dgmpp::Drone::FIGHTER_SQUADRON_NONE)];
				NCFittingSpaceStructureDronesViewControllerSection* section = [NCFittingSpaceStructureDronesViewControllerSection new];
				section.rows = [[dronesDic allValues] sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"sortKey" ascending:YES]]];
				section.squadron = dgmpp::Drone::FIGHTER_SQUADRON_NONE;
				section.numberOfSlots = -1;
				[sections addObject:section];
			}
			
			for (auto squadron: {dgmpp::Drone::FIGHTER_SQUADRON_HEAVY, dgmpp::Drone::FIGHTER_SQUADRON_LIGHT, dgmpp::Drone::FIGHTER_SQUADRON_SUPPORT}) {
				NSDictionary* dronesDic = squadrons[@(squadron)];
				if (structure->getDroneSquadronLimit(squadron) > 0 || dronesDic) {
					NCFittingSpaceStructureDronesViewControllerSection* section = [NCFittingSpaceStructureDronesViewControllerSection new];
					section.rows = [[dronesDic allValues] sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"sortKey" ascending:YES]]];
					section.squadron = squadron;
					section.numberOfSlots = structure->getDroneSquadronLimit(squadron);

					std::map<int,std::pair<int, int>> squadrons;
					for (NCFittingSpaceStructureDronesViewControllerRow* row in section.rows)
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
		NCFittingSpaceStructureDronesViewControllerSection* section = self.sections[sectionIndex];
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
		NCFittingSpaceStructureDronesViewControllerSection* section = self.sections[sectionIndex];
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
		NCFittingSpaceStructureDronesViewControllerSection* section = self.sections[sectionIndex];
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
			auto structure = self.controller.fit.pilot->getSpaceStructure();
			if (structure->getTotalFighterHangar() > 0)
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
															auto structure = self.controller.fit.pilot->getSpaceStructure();
															
															std::shared_ptr<dgmpp::Drone> sameDrone = nullptr;
															for (const auto& i: structure->getDrones()) {
																if (i->getTypeID() == typeID) {
																	sameDrone = i;
																	break;
																}
															}
															self.controller.engine.engine->beginUpdates();
															int dronesLeft = -1;
															do {
																auto drone = structure->addDrone(typeID);
																int squadronSize = drone->getSquadronSize();
																if (sameDrone) {
																	drone->setTarget(sameDrone->getTarget());
																	drone->setActive(sameDrone->isActive());
																}
																
																for (int i = 1; i < squadronSize; i++) {
																	auto drone = structure->addDrone(typeID);
																	if (sameDrone) {
																		drone->setTarget(sameDrone->getTarget());
																		drone->setActive(sameDrone->isActive());
																	}
																}
																
																if (dronesLeft < 0)
																	dronesLeft = std::max(structure->getDroneSquadronLimit(drone->getSquadron()), 1);
																dronesLeft--;
															}
															while (dronesLeft > 0);
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
	/*NCFittingSpaceStructureDronesViewControllerRow* row = indexPath.row < self.rows.count ? self.rows[indexPath.row] : nil;
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
		NCFittingSpaceStructureDronesViewControllerSection* section = self.sections[indexPath.section];
		NCFittingSpaceStructureDronesViewControllerRow* row = section.rows[indexPath.row];
		NCFittingShipDroneCell* cell = (NCFittingShipDroneCell*) tableViewCell;
		
		cell.typeNameLabel.text = row.typeName;
		cell.typeImageView.image = row.typeImage ?: self.defaultTypeImage;
		cell.optimalLabel.text = row.optimalText;
		cell.stateImageView.image = row.stateImage;
		cell.targetImageView.image = row.hasTarget ? self.targetImage : nil;
		
		if (row && !row.isUpToDate) {
			row.isUpToDate = YES;
			[self.controller.engine performBlock:^{
				NCFittingSpaceStructureDronesViewControllerRow* newRow = [NCFittingSpaceStructureDronesViewControllerRow new];
				auto drone = row.drones.front();
				int optimal = (int) drone->getMaxRange();
				int falloff = (int) drone->getFalloff();
				float trackingSpeed = drone->getTrackingSpeed();
				
				NCDBInvType* type = [self.controller.engine.databaseManagedObjectContext invTypeWithTypeID:drone->getTypeID()];
				if (section.squadron == dgmpp::Drone::FIGHTER_SQUADRON_NONE)
					newRow.typeName = [NSString stringWithFormat:@"%@ (x%d)", type.typeName, (int) row.drones.size()];
				else
					newRow.typeName = [NSString stringWithFormat:NSLocalizedString(@"%@ (%dx%d)", nil), type.typeName, (int) (row.drones.size() / drone->getSquadronSize()) , (int) drone->getSquadronSize()];
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
	NCFittingSpaceStructureDronesViewControllerSection* section = self.sections[indexPath.section];
	NCFittingSpaceStructureDronesViewControllerRow* row = section.rows[indexPath.row];
	NSMutableArray* actions = [NSMutableArray new];
	
	[self.controller.engine performBlockAndWait:^{
		auto structure = self.controller.fit.pilot->getSpaceStructure();
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
					structure->removeDrone(drone);
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
				textField.text = [NSString stringWithFormat:@"%d", (int) (drones.size() / squadronSize)];
				textField.clearButtonMode = UITextFieldViewModeAlways;
			}];
			[controller addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Ok", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
				int amount = [amountTextField.text intValue];
				if (amount > 0) {
					if (amount > 50)
						amount = 50;
					
					int n = (int) drones.size() - amount * squadronSize;
					[self.controller.engine performBlock:^{
						self.controller.engine.engine->beginUpdates();
						if (n > 0) {
							int i = n;
							for (const auto& drone: drones) {
								if (i <= 0)
									break;
								structure->removeDrone(drone);
								i--;
							}
						}
						else {
							auto drone = drones.front();
							for (int i = n; i < 0; i++) {
								auto newDrone = structure->addDrone(drone->getTypeID());
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
