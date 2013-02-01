//
//  DronesViewController.m
//  EVEUniverse
//
//  Created by Artem Shimanski on 5/11/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "DronesViewController.h"
#import "EVEDBAPI.h"
#import "FittingViewController.h"
#import "ModuleCellView.h"
#import "UITableViewCell+Nib.h"
#import "FittingItemsViewController.h"
#import "NSString+Fitting.h"
#import "ItemViewController.h"
#import "EUOperationQueue.h"
#import "ItemInfo.h"
#import "ShipFit.h"

#include "eufe.h"

#define ActionButtonActivate NSLocalizedString(@"Activate", nil)
#define ActionButtonDeactivate NSLocalizedString(@"Deactivate", nil)
#define ActionButtonAmount NSLocalizedString(@"Set Amount", nil)
#define ActionButtonCancel NSLocalizedString(@"Cancel", nil)
#define ActionButtonDelete NSLocalizedString(@"Delete", nil)
#define ActionButtonShowInfo NSLocalizedString(@"Show Info", nil)
#define ActionButtonSetTarget NSLocalizedString(@"Set Target", nil)
#define ActionButtonClearTarget NSLocalizedString(@"Clear Target", nil)


@implementation DronesViewController
@synthesize fittingViewController;
@synthesize tableView;
@synthesize droneBayLabel;
@synthesize droneBandwidthLabel;
@synthesize dronesCountLabel;
@synthesize fittingItemsViewController;
@synthesize targetsViewController;
@synthesize popoverController;

// The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
/*
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization.
    }
    return self;
}
*/

/*
// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
}
*/

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		return YES;
	else
		return UIInterfaceOrientationIsPortrait(toInterfaceOrientation);
}

- (void) viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	[self update];
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc. that aren't in use.
}

- (void)viewDidUnload {
    [super viewDidUnload];
	self.tableView = nil;
	self.droneBayLabel = nil;
	self.droneBandwidthLabel = nil;
	self.dronesCountLabel = nil;
	
/*	[rows release];
	[modifiedIndexPath release];
	rows = nil;
	modifiedIndexPath = nil;*/
}


- (void)dealloc {
	[tableView release];
	[droneBayLabel release];
	[droneBandwidthLabel release];
	[dronesCountLabel release];
	[fittingItemsViewController release];
	[targetsViewController release];
	[popoverController release];
	[rows release];
	[modifiedIndexPath release];
    [super dealloc];
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return rows.count + 1;
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
	if (indexPath.row >= rows.count) {
		NSString *cellIdentifier = @"ModuleCellView";
		ModuleCellView *cell = (ModuleCellView*) [aTableView dequeueReusableCellWithIdentifier:cellIdentifier];
		if (cell == nil) {
			cell = [ModuleCellView cellWithNibName:@"ModuleCellView" bundle:nil reuseIdentifier:cellIdentifier];
		}
		cell.iconView.image = [UIImage imageNamed:@"drone.png"];
		cell.stateView.image = nil;
		cell.titleLabel.text = NSLocalizedString(@"Add Drone", nil);
		cell.targetView.image = nil;
		return cell;
	}
	else {
		//EVEFittingDrone *drone = [rows objectAtIndex:indexPath.row];
		NSArray* array = [rows objectAtIndex:indexPath.row];
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
		
		ModuleCellView *cell = (ModuleCellView*) [aTableView dequeueReusableCellWithIdentifier:cellIdentifier];
		if (cell == nil) {
			cell = [ModuleCellView cellWithNibName:@"ModuleCellView" bundle:nil reuseIdentifier:cellIdentifier];
		}
		
		cell.titleLabel.text = [NSString stringWithFormat:@"%@ (x%d)", itemInfo.typeName, array.count];
		cell.iconView.image = [UIImage imageNamed:[itemInfo typeSmallImageName]];
		
		if (optimal > 0) {
			NSString *s = [NSString stringWithFormat:@"%@m", [NSNumberFormatter localizedStringFromNumber:[NSNumber numberWithInt:optimal] numberStyle:NSNumberFormatterDecimalStyle]];
			if (falloff > 0)
				s = [s stringByAppendingFormat:@" + %@m", [NSNumberFormatter localizedStringFromNumber:[NSNumber numberWithInt:falloff] numberStyle:NSNumberFormatterDecimalStyle]];
			if (trackingSpeed > 0)
				s = [s stringByAppendingFormat:@" (%@ rad/sec)", [NSNumberFormatter localizedStringFromNumber:[NSNumber numberWithFloat:trackingSpeed] numberStyle:NSNumberFormatterDecimalStyle]];
			cell.row1Label.text = s;
		}
		
		
		if (drone->isActive())
			cell.stateView.image = [UIImage imageNamed:@"active.png"];
		else
			cell.stateView.image = [UIImage imageNamed:@"offline.png"];
		
		cell.targetView.image = drone->getTarget() != NULL ? [UIImage imageNamed:@"Icons/icon04_12.png"] : nil;

		return cell;
	}
}


#pragma mark -
#pragma mark Table view delegate

- (CGFloat)tableView:(UITableView *)aTableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return [[self tableView:aTableView cellForRowAtIndexPath:indexPath] frame].size.height;
}

- (void)tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[aTableView deselectRowAtIndexPath:indexPath animated:YES];
	if (indexPath.row >= rows.count) {
/*		fittingItemsViewController.groupsRequest = @"SELECT * FROM invGroups WHERE groupID IN (97,100,101,299,470,544,545,549,639,640,641,1023,1159) ORDER BY groupName;";
		fittingItemsViewController.typesRequest = @"SELECT invMetaGroups.metaGroupID, invMetaGroups.metaGroupName, invTypes.* FROM invTypes LEFT JOIN invMetaTypes ON invMetaTypes.typeID=invTypes.typeID LEFT JOIN invMetaGroups ON invMetaTypes.metaGroupID=invMetaGroups.metaGroupID  WHERE invTypes.published=1 AND groupID IN (97,100,101,299,470,544,545,549,639,640,641,1023,97,100,101,299,470,544,545,549,639,640,641,1023,1159) %@ %@ ORDER BY invTypes.typeName;";
		fittingItemsViewController.group = nil;
		fittingItemsViewController.modifiedItem = nil;*/
		fittingItemsViewController.marketGroupID = 157;
		fittingItemsViewController.title = NSLocalizedString(@"Drones", nil);
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
			[popoverController presentPopoverFromRect:[tableView rectForRowAtIndexPath:indexPath] inView:tableView permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
		else
			[self.fittingViewController presentModalViewController:fittingItemsViewController.navigationController animated:YES];
	}
	else {
		//EVEFittingDrone *drone = [rows objectAtIndex:indexPath.row];
		NSArray* array = [rows objectAtIndex:indexPath.row];
		ItemInfo* itemInfo = [array objectAtIndex:0];
		eufe::Drone* drone = dynamic_cast<eufe::Drone*>(itemInfo.item);
		
		UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil
																 delegate:self
														cancelButtonTitle:nil
												   destructiveButtonTitle:nil
														otherButtonTitles:nil];
		[actionSheet addButtonWithTitle:ActionButtonShowInfo];
		//if (drone.amountActive > 0)
		if (drone->isActive())
			[actionSheet addButtonWithTitle:ActionButtonDeactivate];
		else
			[actionSheet addButtonWithTitle:ActionButtonActivate];
		[actionSheet addButtonWithTitle:ActionButtonAmount];
		
		if (fittingViewController.fits.count > 1) {
			[actionSheet addButtonWithTitle:ActionButtonSetTarget];
			if (drone->getTarget() != NULL)
				[actionSheet addButtonWithTitle:ActionButtonClearTarget];
		}

		[actionSheet addButtonWithTitle:ActionButtonDelete];
		[actionSheet addButtonWithTitle:ActionButtonCancel];
		actionSheet.destructiveButtonIndex = actionSheet.numberOfButtons - 2;
		actionSheet.cancelButtonIndex = actionSheet.numberOfButtons - 1;
		
		[actionSheet showFromRect:[aTableView rectForRowAtIndexPath:indexPath] inView:aTableView animated:YES];
		[actionSheet autorelease];
		[modifiedIndexPath release];
		modifiedIndexPath = [indexPath retain];
	}
}

#pragma mark FittingItemsViewControllerDelegate

- (void) fittingItemsViewController:(FittingItemsViewController*) aController didSelectType:(EVEDBInvType*) type {
	eufe::Ship* ship = fittingViewController.fit.character->getShip();
	eufe::Drone* drone = ship->addDrone(type.typeID);
	
	int dronesLeft = ship->getMaxActiveDrones() - 1;
	for (;dronesLeft > 0; dronesLeft--)
		ship->addDrone(new eufe::Drone(*drone));

	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		[popoverController dismissPopoverAnimated:YES];
	else
		[self.fittingViewController dismissModalViewControllerAnimated:YES];
	[fittingViewController update];
}

#pragma mark DronesAmountViewControllerDelegate

- (void) dronesAmountViewController:(DronesAmountViewController*) aController didSelectAmount:(NSInteger) amount {
	eufe::Ship* ship = fittingViewController.fit.character->getShip();
	NSMutableArray* drones = [rows objectAtIndex:modifiedIndexPath.row];
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
	[fittingViewController update];
}

- (void) dronesAmountViewControllerDidCancel:(DronesAmountViewController*) controller {
}

#pragma mark UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
	NSArray* array = [rows objectAtIndex:modifiedIndexPath.row];
	eufe::Ship* ship = fittingViewController.fit.character->getShip();
	NSString *button = [actionSheet buttonTitleAtIndex:buttonIndex];
	if ([button isEqualToString:ActionButtonDelete]) {
		for (ItemInfo* itemInfo in array)
			ship->removeDrone(dynamic_cast<eufe::Drone*>(itemInfo.item));
		[fittingViewController update];
	}
	else if ([button isEqualToString:ActionButtonActivate]) {
		for (ItemInfo* itemInfo in array)
			dynamic_cast<eufe::Drone*>(itemInfo.item)->setActive(true);
		[fittingViewController update];
	}
	else if ([button isEqualToString:ActionButtonDeactivate]) {
		for (ItemInfo* itemInfo in array)
			dynamic_cast<eufe::Drone*>(itemInfo.item)->setActive(false);
		[fittingViewController update];
	}
	else if ([button isEqualToString:ActionButtonAmount]) {
		DronesAmountViewController *dronesAmountViewController = [[DronesAmountViewController alloc] initWithNibName:@"DronesAmountViewController" bundle:nil];
		dronesAmountViewController.amount = array.count;
		int maxActiveDrones = ship->getMaxActiveDrones();
		dronesAmountViewController.maxAmount = maxActiveDrones > 0 ? maxActiveDrones : 5;
		dronesAmountViewController.delegate = self;
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
			[dronesAmountViewController presentPopoverFromRect:[tableView rectForRowAtIndexPath:modifiedIndexPath] inView:tableView permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
		else
			[dronesAmountViewController presentAnimated:YES];
		[dronesAmountViewController release];
	}
	else if ([button isEqualToString:ActionButtonSetTarget]) {
		ItemInfo* itemInfo = [array objectAtIndex:0];
		eufe::Drone* drone = dynamic_cast<eufe::Drone*>(itemInfo.item);
		targetsViewController.modifiedItem = itemInfo;
		targetsViewController.currentTarget = drone->getTarget();
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
			[fittingViewController.targetsPopoverController presentPopoverFromRect:[tableView rectForRowAtIndexPath:modifiedIndexPath] inView:tableView permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
		else
			[self.fittingViewController presentModalViewController:targetsViewController.navigationController animated:YES];
	}
	else if ([button isEqualToString:ActionButtonClearTarget]) {
		for (ItemInfo* itemInfo in array)
			dynamic_cast<eufe::Drone*>(itemInfo.item)->clearTarget();
		[fittingViewController update];
	}
	else if ([button isEqualToString:ActionButtonShowInfo]) {
		ItemViewController *itemViewController = [[ItemViewController alloc] initWithNibName:@"ItemViewController" bundle:nil];
		
		//itemViewController.type = drone.item;
		ItemInfo* itemInfo = [array objectAtIndex:0];
		[itemInfo updateAttributes];
		itemViewController.type = itemInfo;
		[itemViewController setActivePage:ItemViewControllerActivePageInfo];
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
			UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:itemViewController];
			navController.modalPresentationStyle = UIModalPresentationFormSheet;
			[fittingViewController presentModalViewController:navController animated:YES];
			[navController release];
		}
		else
			[fittingViewController.navigationController pushViewController:itemViewController animated:YES];
		[itemViewController release];
	}
}

#pragma mark FittingSection

- (void) update {
	__block float totalDB;
	__block float usedDB;
	__block float totalBandwidth;
	__block float usedBandwidth;
	__block int maxActiveDrones;
	__block int activeDrones;
	NSMutableArray *rowsTmp = [NSMutableArray array];
	FittingViewController* aFittingViewController = fittingViewController;
	
	__block EUOperation *operation = [EUOperation operationWithIdentifier:@"DronesViewController+Update" name:NSLocalizedString(@"Updating Drones", nil)];
	[operation addExecutionBlock:^(void) {
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		@synchronized(fittingViewController) {
			
			eufe::Ship* ship = aFittingViewController.fit.character->getShip();
			NSMutableDictionary* dronesDic = [NSMutableDictionary dictionary];
			
			const eufe::DronesList& drones = ship->getDrones();
			eufe::DronesList::const_iterator i, end = drones.end();
			
			float n = drones.size();
			float j = 0;
			for (i = drones.begin(); i != end; i++) {
				operation.progress = j++ / n;

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
		[pool release];
	}];
	
	[operation setCompletionBlockInCurrentThread:^(void) {
		if (![operation isCancelled]) {
			if (rows)
				[rows release];
			rows = [rowsTmp retain];
			droneBayLabel.text = [NSString stringWithTotalResources:totalDB usedResources:usedDB unit:@"m3"];
			droneBayLabel.progress = totalDB > 0 ? usedDB / totalDB : 0;
			droneBandwidthLabel.text = [NSString stringWithTotalResources:totalBandwidth usedResources:usedBandwidth unit:@"Mbit/s"];
			droneBandwidthLabel.progress = totalBandwidth > 0 ? usedBandwidth / totalBandwidth : 0;
			dronesCountLabel.text = [NSString stringWithFormat:@"%d/%d", activeDrones, maxActiveDrones];
			if (activeDrones > maxActiveDrones)
				dronesCountLabel.textColor = [UIColor redColor];
			else
				dronesCountLabel.textColor = [UIColor whiteColor];
			
			[tableView reloadData];
		}
	}];
	
	[[EUOperationQueue sharedQueue] addOperation:operation];
}

@end