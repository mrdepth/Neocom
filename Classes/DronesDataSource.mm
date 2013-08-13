//
//  DronesDataSource.m
//  EVEUniverse
//
//  Created by mr_depth on 03.08.13.
//
//

#import "DronesDataSource.h"
#import "EUOperationQueue.h"
#import "FittingViewController.h"
#import "NSNumberFormatter+Neocom.h"
#import "UIActionSheet+Block.h"
#import "UIActionSheet+Neocom.h"
#import "ModuleCellView.h"
#import "UITableViewCell+Nib.h"
#import "UIViewController+Neocom.h"
#import "NSNumberFormatter+Neocom.h"
#import "ItemViewController.h"
#import "AmountViewController.h"
#import "NSString+Fitting.h"

#define ActionButtonActivate NSLocalizedString(@"Activate", nil)
#define ActionButtonDeactivate NSLocalizedString(@"Deactivate", nil)
#define ActionButtonAmount NSLocalizedString(@"Set Amount", nil)
#define ActionButtonCancel NSLocalizedString(@"Cancel", nil)
#define ActionButtonDelete NSLocalizedString(@"Delete", nil)
#define ActionButtonShowInfo NSLocalizedString(@"Show Info", nil)
#define ActionButtonSetTarget NSLocalizedString(@"Set Target", nil)
#define ActionButtonClearTarget NSLocalizedString(@"Clear Target", nil)

@interface DronesDataSource()
@property (nonatomic, strong) NSArray* rows;
- (void) performActionForRowAtIndexPath:(NSIndexPath*) indexPath;
@end

@implementation DronesDataSource

- (void) reload {
	__block float totalDB;
	__block float usedDB;
	__block float totalBandwidth;
	__block float usedBandwidth;
	__block int maxActiveDrones;
	__block int activeDrones;
	NSMutableArray *rowsTmp = [NSMutableArray array];
	
	__block EUOperation *operation = [EUOperation operationWithIdentifier:@"DronesDataSource+reload" name:NSLocalizedString(@"Updating Drones", nil)];
	__weak EUOperation* weakOperation = operation;
	[operation addExecutionBlock:^(void) {
		@synchronized(self.fittingViewController) {
			
			eufe::Ship* ship = self.fittingViewController.fit.character->getShip();
			NSMutableDictionary* dronesDic = [NSMutableDictionary dictionary];
			
			const eufe::DronesList& drones = ship->getDrones();
			eufe::DronesList::const_iterator i, end = drones.end();
			
			float n = drones.size();
			float j = 0;
			for (i = drones.begin(); i != end; i++) {
				weakOperation.progress = j++ / n;
				
				NSString* key = [NSString stringWithFormat:@"%d", (*i)->getTypeID()];
				NSMutableArray* array = [dronesDic valueForKey:key];
				if (!array) {
					array = [NSMutableArray array];
					[dronesDic setValue:array forKey:key];
					[rowsTmp addObject:array];
				}
				[array addObject:[ItemInfo itemInfoWithItem:*i error:nil]];
			}
			
			totalDB = ship->getTotalDroneBay();
			usedDB = ship->getDroneBayUsed();
			
			totalBandwidth = ship->getTotalDroneBandwidth();
			usedBandwidth = ship->getDroneBandwidthUsed();
			
			maxActiveDrones = ship->getMaxActiveDrones();
			activeDrones = ship->getActiveDrones();
		}
	}];
	
	[operation setCompletionBlockInMainThread:^(void) {
		if (![weakOperation isCancelled]) {
			self.rows = rowsTmp;
			if (self.tableView.dataSource == self)
				[self.tableView reloadData];
			self.droneBayLabel.text = [NSString stringWithTotalResources:totalDB usedResources:usedDB unit:@"m3"];
			self.droneBayLabel.progress = totalDB > 0 ? usedDB / totalDB : 0;
			self.droneBandwidthLabel.text = [NSString stringWithTotalResources:totalBandwidth usedResources:usedBandwidth unit:@"Mbit/s"];
			self.droneBandwidthLabel.progress = totalBandwidth > 0 ? usedBandwidth / totalBandwidth : 0;
			self.dronesCountLabel.text = [NSString stringWithFormat:@"%d/%d", activeDrones, maxActiveDrones];
			if (activeDrones > maxActiveDrones)
				self.dronesCountLabel.textColor = [UIColor redColor];
			else
				self.dronesCountLabel.textColor = [UIColor whiteColor];
		}
	}];
	
	[[EUOperationQueue sharedQueue] addOperation:operation];
}

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
		NSString *cellIdentifier = @"ModuleCellView";
		ModuleCellView *cell = (ModuleCellView*) [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
		if (cell == nil) {
			cell = [ModuleCellView cellWithNibName:@"ModuleCellView" bundle:nil reuseIdentifier:cellIdentifier];
		}
		cell.iconView.image = [UIImage imageNamed:@"drone.png"];
		cell.stateView.image = nil;
		cell.titleLabel.text = NSLocalizedString(@"Add Drone", nil);
		cell.targetView.image = nil;
		
		int groupStyle = 0;
		if (indexPath.row == 0)
			groupStyle |= GroupedCellGroupStyleTop;
		if (indexPath.row == [self tableView:tableView numberOfRowsInSection:indexPath.section] - 1)
			groupStyle |= GroupedCellGroupStyleBottom;
		cell.groupStyle = static_cast<GroupedCellGroupStyle>(groupStyle);
		return cell;
	}
	else {
		//EVEFittingDrone *drone = [rows objectAtIndex:indexPath.row];
		NSArray* array = [self.rows objectAtIndex:indexPath.row];
		ItemInfo* itemInfo = [array objectAtIndex:0];
		eufe::Drone* drone = dynamic_cast<eufe::Drone*>(itemInfo.item);
		
		int optimal = (int) drone->getMaxRange();
		int falloff = (int) drone->getFalloff();
		float trackingSpeed = drone->getTrackingSpeed();
		
		NSString *cellIdentifier;
		int additionalRows = 0;
		if (optimal > 0)
			additionalRows = 1;
		else
			additionalRows = 0;
		
		if (additionalRows > 0)
			cellIdentifier = [NSString stringWithFormat:@"ModuleCellView%d", additionalRows];
		else
			cellIdentifier = @"ModuleCellView";
		
		ModuleCellView *cell = (ModuleCellView*) [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
		if (cell == nil) {
			cell = [ModuleCellView cellWithNibName:@"ModuleCellView" bundle:nil reuseIdentifier:cellIdentifier];
		}
		
		cell.titleLabel.text = [NSString stringWithFormat:@"%@ (x%d)", itemInfo.typeName, array.count];
		cell.iconView.image = [UIImage imageNamed:[itemInfo typeSmallImageName]];
		
		if (optimal > 0) {
			NSString *s = [NSString stringWithFormat:NSLocalizedString(@"%@m", nil), [NSNumberFormatter neocomLocalizedStringFromNumber:@(optimal)]];
			if (falloff > 0)
				s = [s stringByAppendingFormat:NSLocalizedString(@" + %@m", nil), [NSNumberFormatter neocomLocalizedStringFromNumber:@(falloff)]];
			if (trackingSpeed > 0)
				s = [s stringByAppendingFormat:NSLocalizedString(@" (%@ rad/sec)", nil), [NSNumberFormatter neocomLocalizedStringFromNumber:@(trackingSpeed)]];
			cell.row1Label.text = s;
		}
		
		
		if (drone->isActive())
			cell.stateView.image = [UIImage imageNamed:@"active.png"];
		else
			cell.stateView.image = [UIImage imageNamed:@"offline.png"];
		
		cell.targetView.image = drone->getTarget() != NULL ? [UIImage imageNamed:@"Icons/icon04_12.png"] : nil;
		
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
	return 40;
}

- (void)tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[aTableView deselectRowAtIndexPath:indexPath animated:YES];
	if (indexPath.row >= self.rows.count) {
		self.fittingViewController.itemsViewController.conditions = @[@"invGroups.groupID = invTypes.groupID", @"invGroups.categoryID = 18"];
		self.fittingViewController.itemsViewController.title = NSLocalizedString(@"Drones", nil);
		
		
		self.fittingViewController.itemsViewController.completionHandler = ^(EVEDBInvType* type) {
			eufe::TypeID typeID = type.typeID;
			eufe::Ship* ship = self.fittingViewController.fit.character->getShip();
			
			const eufe::DronesList& drones = ship->getDrones();
			eufe::Drone* sameDrone = NULL;
			eufe::DronesList::const_iterator i, end = drones.end();
			for (i = drones.begin(); i != end; i++) {
				if ((*i)->getTypeID() == typeID) {
					sameDrone = *i;
					break;
				}
			}
			eufe::Drone* drone = ship->addDrone(type.typeID);
			
			if (sameDrone)
				drone->setTarget(sameDrone->getTarget());
			else {
				int dronesLeft = ship->getMaxActiveDrones() - 1;
				for (;dronesLeft > 0; dronesLeft--)
					ship->addDrone(new eufe::Drone(*drone));
			}
			
			[self.fittingViewController dismiss];

			[self.fittingViewController update];
		};
		
		[self.fittingViewController presentViewController:self.fittingViewController.itemsViewController animated:YES completion:nil];
//		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
//			[self.popoverController presentPopoverFromRect:[self.tableView rectForRowAtIndexPath:indexPath] inView:self.tableView permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
//		else
//			[self.self.fittingViewController presentModalViewController:self.fittingItemsViewController.navigationController animated:YES];
	}
	else {
		//EVEFittingDrone *drone = [rows objectAtIndex:indexPath.row];
		[self performActionForRowAtIndexPath:indexPath];
	}
}

#pragma mark - Private

- (void) performActionForRowAtIndexPath:(NSIndexPath*) indexPath {
	NSArray* drones = [self.rows objectAtIndex:indexPath.row];
	
	eufe::Ship* ship = self.fittingViewController.fit.character->getShip();
	ItemInfo* itemInfo = [drones objectAtIndex:0];
	eufe::Drone* drone = dynamic_cast<eufe::Drone*>(itemInfo.item);
	
	void (^remove)(NSArray*) = ^(NSArray* drones){
		for (ItemInfo* itemInfo in drones) {
			eufe::Drone* drone = dynamic_cast<eufe::Drone*>(itemInfo.item);
			self.fittingViewController.fit.character->getShip()->removeDrone(drone);
		}
		[self.fittingViewController update];
	};
	
	void (^activate)(NSArray*) = ^(NSArray* drones){
		for (ItemInfo* itemInfo in drones) {
			eufe::Drone* drone = dynamic_cast<eufe::Drone*>(itemInfo.item);
			drone->setActive(true);
		}
		[self.fittingViewController update];
	};

	void (^deactivate)(NSArray*) = ^(NSArray* drones){
		for (ItemInfo* itemInfo in drones) {
			eufe::Drone* drone = dynamic_cast<eufe::Drone*>(itemInfo.item);
			drone->setActive(false);
		}
		[self.fittingViewController update];
	};

	void (^setTarget)(NSArray*) = ^(NSArray* drones){
		TargetsViewController* controller = [[TargetsViewController alloc] initWithNibName:@"TargetsViewController" bundle:nil];
		controller.currentTarget = drone->getTarget();
		controller.fittingViewController = self.fittingViewController;
		UINavigationController* navigationController = [[UINavigationController alloc] initWithRootViewController:controller];
		controller.completionHandler = ^(eufe::Ship* target) {
			for (ItemInfo* itemInfo in drones) {
				eufe::Drone* drone = dynamic_cast<eufe::Drone*>(itemInfo.item);
				drone->setTarget(target);
			}
			[self.fittingViewController update];
			[self.fittingViewController dismiss];
		};
		
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		}
		else
			[self.fittingViewController presentViewController:navigationController animated:YES completion:nil];
	};
	
	void (^clearTarget)(NSArray*) = ^(NSArray* drones){
		for (ItemInfo* itemInfo in drones) {
			eufe::Drone* drone = dynamic_cast<eufe::Drone*>(itemInfo.item);
			drone->clearTarget();
		}
		[self.fittingViewController update];
	};
	
	void (^setAmount)(NSArray*) = ^(NSArray* drones){
		AmountViewController *controller = [[AmountViewController alloc] initWithNibName:@"AmountViewController" bundle:nil];
		controller.amount = drones.count;
		int maxActiveDrones = ship->getMaxActiveDrones();
		controller.maxAmount = maxActiveDrones > 0 ? maxActiveDrones : 5;
		
		controller.completionHandler = ^(NSInteger amount) {
			int left = drones.count - amount;
			if (left < 0) {
				ItemInfo* itemInfo = [drones objectAtIndex:0];
				eufe::Drone* drone = dynamic_cast<eufe::Drone*>(itemInfo.item);
				for (;left < 0; left++)
					ship->addDrone(new eufe::Drone(*drone))->setTarget(drone->getTarget());
			}
			else if (left > 0) {
				int i = drones.count - 1;
				for (; left > 0; left--) {
					ItemInfo* itemInfo = [drones objectAtIndex:i--];
					eufe::Drone* drone = dynamic_cast<eufe::Drone*>(itemInfo.item);
					ship->removeDrone(drone);
				}
			}
			[self.fittingViewController update];
		};
		
		UINavigationController* navigationController = [[UINavigationController alloc] initWithRootViewController:controller];
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
			[controller presentViewControllerInPopover:self.fittingViewController
											  fromRect:[self.tableView rectForRowAtIndexPath:indexPath]
												inView:self.tableView
							  permittedArrowDirections:UIPopoverArrowDirectionAny
											  animated:YES];
		else {
			controller.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Close", nil) style:UIBarButtonItemStyleBordered target:self action:@selector(dismiss)];
			[self.fittingViewController presentViewController:navigationController animated:YES completion:nil];
		}
	};

	void (^showInfo)(NSArray*) = ^(NSArray* modules){
		ItemViewController *itemViewController = [[ItemViewController alloc] initWithNibName:@"ItemViewController" bundle:nil];
		[itemInfo updateAttributes];
		itemViewController.type = itemInfo;
		[itemViewController setActivePage:ItemViewControllerActivePageInfo];
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
			UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:itemViewController];
			navController.modalPresentationStyle = UIModalPresentationFormSheet;
			[self.fittingViewController presentViewController:navController animated:YES completion:nil];
		}
		else
			[self.fittingViewController.navigationController pushViewController:itemViewController animated:YES];
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
	
	if (self.fittingViewController.fits.count > 1) {
		[buttons addObject:ActionButtonSetTarget];
		[actions addObject:setTarget];
		if (drone->getTarget() != NULL) {
			[buttons addObject:ActionButtonClearTarget];
			[actions addObject:clearTarget];
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
								 block(drones);
							 }
						 } cancelBlock:nil] showInWindowFromRect:[self.tableView rectForRowAtIndexPath:indexPath] inView:self.tableView animated:YES];

}

@end
