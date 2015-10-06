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
#import "UIActionSheet+Block.h"
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

@interface NCFittingShipDronesViewControllerRow : NSObject {
	eufe::DronesList _drones;
}
@property (nonatomic, strong) NCDBInvType* type;
@property (nonatomic, readonly) eufe::DronesList& drones;

@property (nonatomic, strong) NSString* typeName;
@property (nonatomic, strong) UIImage* typeImage;
@property (nonatomic, strong) NSString* optimalText;
@property (nonatomic, strong) UIImage* targetImage;
@property (nonatomic, strong) UIImage* stateImage;
@end

@interface NCFittingShipDronesViewControllerPickerRow : NSObject
@property (nonatomic, strong) NCFittingShipDronesViewControllerRow* associatedRow;
@end

@implementation NCFittingShipDronesViewControllerRow

@end

@implementation NCFittingShipDronesViewControllerPickerRow

@end

@interface NCFittingShipDronesViewController()<UIPickerViewDataSource, UIPickerViewDelegate>
@property (nonatomic, strong) NCDBInvType* activeAmountType;
@property (nonatomic, assign) NSInteger maximumAmount;
@property (nonatomic, strong) NSArray* rows;
@property (nonatomic, strong) NCDBEveIcon* defaultTypeIcon;
@property (nonatomic, strong) NCDBEveIcon* targetIcon;

- (void) performActionForRowAtIndexPath:(NSIndexPath*) indexPath;

@end

@implementation NCFittingShipDronesViewController

- (void) viewDidLoad {
	[super viewDidLoad];
	self.defaultTypeIcon = [self.databaseManagedObjectContext defaultTypeIcon];
	self.targetIcon = [self.databaseManagedObjectContext eveIconWithIconFile:@"04_12"];
}

- (void) reload {
	__block NSMutableArray* rows = nil;
	[self.controller.engine performBlockAndWait:^{
		rows = [NSMutableArray new];
		if (!self.controller.fit.pilot)
			return;

		NSMutableDictionary* dronesDic = [NSMutableDictionary new];
		eufe::DronesList drones;
		if (!self.controller.fit.pilot)
			return;
		
		auto ship = self.controller.fit.pilot->getShip();
		for (auto drone: ship->getDrones()) {
			int32_t typeID = drone->getTypeID();
			NCFittingShipDronesViewControllerRow* row = dronesDic[@(typeID)];
			if (!row) {
				row = [NCFittingShipDronesViewControllerRow new];
				row.type = [self.controller.engine invTypeWithTypeID:typeID];
				dronesDic[@(typeID)] = row;
			}
			row.drones.push_back(drone);
		}
		
		rows = [[[dronesDic allValues] sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"type.typeName" ascending:YES]]] mutableCopy];
		if (self.activeAmountType) {
			NSInteger i = 1;
			for (NCFittingShipDronesViewControllerRow* row in rows) {
				if (row.type.typeID == self.activeAmountType.typeID) {
					NCFittingShipDronesViewControllerPickerRow* pickerRow = [NCFittingShipDronesViewControllerPickerRow new];
					pickerRow.associatedRow = row;
					[rows insertObject:pickerRow atIndex:i];
					break;
				}
				i++;
			}
		}
	}];
	self.rows = rows;
	[self.tableView reloadData];
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

- (void) tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
	[super tableView:tableView willDisplayCell:cell forRowAtIndexPath:indexPath];
	if ([cell isKindOfClass:[NCFittingAmountCell class]]) {
		NCFittingShipDronesViewControllerPickerRow* pickerRow = self.rows[indexPath.row];
		NCFittingAmountCell* amountCell = (NCFittingAmountCell*) cell;
		amountCell.pickerView.dataSource = self;
		amountCell.pickerView.delegate = self;
		[amountCell.pickerView reloadAllComponents];
		[amountCell.pickerView selectRow:pickerRow.associatedRow.drones.size() - 1 inComponent:0 animated:NO];
	}
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	NSInteger i = 0;
	for (NCFittingShipDronesViewControllerRow* row in self.rows) {
		if ([row isKindOfClass:[NCFittingShipDronesViewControllerPickerRow class]]) {
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
		self.controller.typePickerViewController.title = NSLocalizedString(@"Drones", nil);
		
		[self.controller.typePickerViewController presentWithCategory:[self.databaseManagedObjectContext categoryWithSlot:NCDBEufeItemSlotDrone size:0 race:nil]
													 inViewController:self.controller
															 fromRect:cell.bounds
															   inView:cell
															 animated:YES
													completionHandler:^(NCDBInvType *type) {
														[self.controller.engine performBlockAndWait:^{
															eufe::TypeID typeID = type.typeID;
															auto ship = self.controller.fit.pilot->getShip();
															
															std::shared_ptr<eufe::Drone> sameDrone = nullptr;
															for (auto i: ship->getDrones()) {
																if (i->getTypeID() == typeID) {
																	sameDrone = i;
																	break;
																}
															}
															int dronesLeft = std::max(ship->getMaxActiveDrones() - 1, 1);
															for (;dronesLeft > 0; dronesLeft--) {
																auto drone = ship->addDrone(typeID);
																if (sameDrone) {
																	drone->setTarget(sameDrone->getTarget());
																	drone->setActive(sameDrone->isActive());
																}
															}
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

#pragma mark - UIPickerViewDataSource

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
	return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
	return self.maximumAmount;
}

- (NSString*) pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
	return [NSString stringWithFormat:@"%ld", (long)(row + 1)];
}

- (void) pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)rowIndex inComponent:(NSInteger)component {
	int amount = (int) (rowIndex + 1);
	NSInteger i = 0;
	for (NCFittingShipDronesViewControllerPickerRow* row in self.rows) {
		if ([row isKindOfClass:[NCFittingShipDronesViewControllerPickerRow class]]) {
			[self.controller.engine performBlockAndWait:^{
				auto ship = self.controller.fit.pilot->getShip();
				eufe::TypeID typeID = row.associatedRow.drones.front()->getTypeID();
				
				if (row.associatedRow.drones.size() > amount) {
					int n = (int) row.associatedRow.drones.size() - amount;
					for (auto drone: row.associatedRow.drones) {
						if (n <= 0)
							break;
						ship->removeDrone(drone);
						n--;
					}
				}
				else {
					int n = amount - (int) row.associatedRow.drones.size();
					auto drone = row.associatedRow.drones.front();
					for (int i = 0; i < n; i++) {
						auto newDrone = ship->addDrone(drone->getTypeID());
						newDrone->setActive(drone->isActive());
						newDrone->setTarget(drone->getTarget());
					}
				}
				row.associatedRow.drones.clear();
				for (auto drone: ship->getDrones()) {
					if (drone->getTypeID() == typeID)
						row.associatedRow.drones.push_back(drone);
				}
				[NSObject cancelPreviousPerformRequestsWithTarget:self.controller selector:@selector(reload) object:nil];
				[self.controller performSelector:@selector(reload) withObject:nil afterDelay:0.25];
			}];
		}
		i++;
	}
}

#pragma mark - Private

- (void) performActionForRowAtIndexPath:(NSIndexPath*) indexPath {
	UITableViewCell* cell = [self.tableView cellForRowAtIndexPath:indexPath];
	NCFittingShipDronesViewControllerRow* row = self.rows[indexPath.row];
	
	auto ship = self.controller.fit.pilot->getShip();
	auto drone = row.drones.front();
	
	void (^remove)(eufe::DronesList) = ^(eufe::DronesList drones){
		[self.controller.engine performBlockAndWait:^{
			for (auto drone: drones)
				ship->removeDrone(drone);
		}];
		[self.controller reload];
	};
	
	void (^activate)(eufe::DronesList) = ^(eufe::DronesList drones){
		[self.controller.engine performBlockAndWait:^{
			for (auto drone: drones)
				drone->setActive(true);
		}];
		[self.controller reload];
	};
	
	void (^deactivate)(eufe::DronesList) = ^(eufe::DronesList drones){
		[self.controller.engine performBlockAndWait:^{
			for (auto drone: drones)
				drone->setActive(false);
		}];
		[self.controller reload];
	};
	
	void (^setTarget)(eufe::DronesList) = ^(eufe::DronesList drones){
		NSMutableArray* array = [NSMutableArray new];
		for (auto drone: drones)
			[array addObject:[NCFittingEngineItemPointer pointerWithItem:drone]];
		[self.controller performSegueWithIdentifier:@"NCFittingTargetsViewController"
											 sender:@{@"sender": cell, @"object": array}];
	};
	
	void (^clearTarget)(eufe::DronesList) = ^(eufe::DronesList drones){
		[self.controller.engine performBlockAndWait:^{
			for (auto drone: drones)
				drone->clearTarget();
		}];
		[self.controller reload];
	};
	
	void (^setAmount)(eufe::DronesList) = ^(eufe::DronesList drones) {
		NSMutableArray* rows = [self.rows mutableCopy];
		[self.controller.engine performBlockAndWait:^{
			self.activeAmountType = row.type;
			NCFittingShipDronesViewControllerPickerRow* pickerRow = [NCFittingShipDronesViewControllerPickerRow new];
			pickerRow.associatedRow = row;
			
			float volume = drone->getAttribute(eufe::VOLUME_ATTRIBUTE_ID)->getValue();
			int droneBay = ship->getTotalDroneBay() / volume;
			int maxActive = ship->getMaxActiveDrones();
			self.maximumAmount = std::min(std::max(droneBay, maxActive), 50);
			
			
			[rows insertObject:pickerRow atIndex:indexPath.row + 1];
		}];
		self.rows = rows;
		[self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:indexPath.row + 1 inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
	};
	
	void (^showInfo)(eufe::DronesList) = ^(eufe::DronesList drones) {
		[self.controller performSegueWithIdentifier:@"NCDatabaseTypeInfoViewController"
											 sender:@{@"sender": cell, @"object": [NCFittingEngineItemPointer pointerWithItem:drone]}];
	};
	
	void (^affectingSkills)(eufe::DronesList) = ^(eufe::DronesList drones){
		[self.controller performSegueWithIdentifier:@"NCFittingShipAffectingSkillsViewController"
											 sender:@{@"sender": cell, @"object": [NCFittingEngineItemPointer pointerWithItem:drone]}];
	};
	
	
	NSMutableArray* buttons = [NSMutableArray new];
	NSMutableArray* actions = [NSMutableArray new];
	
	[actions addObject:remove];
	
	[buttons addObject:ActionButtonShowInfo];
	[actions addObject:showInfo];
	if (drone->isActive()) {
		[buttons addObject:ActionButtonDeactivate];
		[actions addObject:deactivate];
	}
	else {
		[buttons addObject:ActionButtonActivate];
		[actions addObject:activate];
	}
	
	[buttons addObject:ActionButtonAmount];
	[actions addObject:setAmount];
	
	[buttons addObject:ActionButtonAffectingSkills];
	[actions addObject:affectingSkills];
	
	if (self.controller.fits.count > 1) {
		[buttons addObject:ActionButtonSetTarget];
		[actions addObject:setTarget];
		if (drone->getTarget() != NULL) {
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
							 [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
							 if (selectedButtonIndex != actionSheet.cancelButtonIndex) {
								 void (^block)(eufe::DronesList) = actions[selectedButtonIndex];
								 block(row.drones);
							 }
						 } cancelBlock:nil] showFromRect:cell.bounds inView:cell animated:YES];
	
}

- (NSString*)tableView:(UITableView *)tableView cellIdentifierForRowAtIndexPath:(NSIndexPath *)indexPath {
	if (indexPath.row >= self.rows.count)
		return @"Cell";
	else {
		NCFittingShipDronesViewControllerRow* row = self.rows[indexPath.row];
		if ([row isKindOfClass:[NCFittingShipDronesViewControllerPickerRow class]])
			return @"NCFittingAmountCell";
		else
			return @"NCFittingShipDroneCell";
	}
}

- (void) tableView:(UITableView *)tableView configureCell:(UITableViewCell*) tableViewCell forRowAtIndexPath:(NSIndexPath*) indexPath {
	if (indexPath.row >= self.rows.count) {
		NCDefaultTableViewCell* cell = (NCDefaultTableViewCell*) tableViewCell;
		cell.iconView.image = [UIImage imageNamed:@"drone.png"];
		cell.titleLabel.text = NSLocalizedString(@"Add Drone", nil);
		cell.subtitleLabel.text = nil;
		cell.accessoryView = nil;
	}
	else {
		NCFittingShipDronesViewControllerRow* row = self.rows[indexPath.row];
		if (![row isKindOfClass:[NCFittingShipDronesViewControllerPickerRow class]]) {
			if (!row.typeName) {
				[self.controller.engine performBlockAndWait:^{
					auto drone = row.drones.front();
					int optimal = (int) drone->getMaxRange();
					int falloff = (int) drone->getFalloff();
					float trackingSpeed = drone->getTrackingSpeed();
					
					NCDBInvType* type = row.type;
					row.typeName = [NSString stringWithFormat:@"%@ (x%d)", type.typeName, (int) row.drones.size()];
					row.typeImage = type.icon ? type.icon.image.image : self.defaultTypeIcon.image.image;
					
					if (optimal > 0) {
						NSString *s = [NSString stringWithFormat:NSLocalizedString(@"%@m", nil), [NSNumberFormatter neocomLocalizedStringFromNumber:@(optimal)]];
						if (falloff > 0)
							s = [s stringByAppendingFormat:NSLocalizedString(@" + %@m", nil), [NSNumberFormatter neocomLocalizedStringFromNumber:@(falloff)]];
						if (trackingSpeed > 0)
							s = [s stringByAppendingFormat:NSLocalizedString(@" (%@ rad/sec)", nil), [NSNumberFormatter neocomLocalizedStringFromNumber:@(trackingSpeed)]];
						row.optimalText = s;
						row.stateImage = drone->isActive() ? [UIImage imageNamed:@"active.png"] : [UIImage imageNamed:@"offline.png"];
						row.targetImage = drone->getTarget() != nullptr ? self.targetIcon.image.image : nil;
					}

				}];
			}
			
			
			NCFittingShipDroneCell* cell = (NCFittingShipDroneCell*) tableViewCell;
			
			cell.typeNameLabel.text = row.typeName;
			cell.typeImageView.image = row.typeImage;
			cell.optimalLabel.text = row.optimalText;
			cell.stateImageView.image = row.stateImage;
			cell.targetImageView.image = row.targetImage;
		}
	}
}

@end
