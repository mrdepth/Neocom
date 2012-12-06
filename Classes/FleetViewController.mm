//
//  FleetViewController.m
//  EVEUniverse
//
//  Created by Mr. Depth on 12/20/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "FleetViewController.h"
#import "FittingViewController.h"
#import "EVEDBAPI.h"
#import "ModuleCellView.h"
#import "FleetMemberCellView.h"
#import "UITableViewCell+Nib.h"
#import "NSString+Fitting.h"
#import "ItemViewController.h"
#import "EUOperationQueue.h"
#import "Fit.h"

#import "ItemInfo.h"

#define ActionButtonCharacter @"Switch Character"
#define ActionButtonDelete @"Delete"
#define ActionButtonSelect @"Set Active Ship"
#define ActionButtonShowShipInfo @"Ship Info"
#define ActionButtonAddShip @"Add Ship"
#define ActionButtonCancel @"Cancel"
#define ActionButtonBooster @"Booster"
#define ActionButtonSetFleetBooster @"Set Fleet Booster"
#define ActionButtonSetWingBooster @"Set Wing Booster"
#define ActionButtonSetSquadBooster @"Set Squad Booster"
#define ActionButtonRemoveBooster @"Remove Booster"

@implementation FleetViewController
@synthesize fittingViewController;
@synthesize tableView;

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

- (void) viewWillAppear:(BOOL)animated {
	[self update];
}

// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		return UIInterfaceOrientationIsLandscape(interfaceOrientation);
	else
		return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc. that aren't in use.
}

- (void)viewDidUnload {
    [super viewDidUnload];
	self.tableView = nil;
/*	[modifiedIndexPath release];
	modifiedIndexPath = nil;
	[pilots release];
	pilots = nil;*/
}


- (void)dealloc {
	[tableView release];
	[modifiedIndexPath release];
	[pilots release];
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
    return pilots.count + 1;
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	if (indexPath.row >= pilots.count) {
		NSString *cellIdentifier = @"ModuleCellView";
		ModuleCellView *cell = (ModuleCellView*) [aTableView dequeueReusableCellWithIdentifier:cellIdentifier];
		if (cell == nil) {
			cell = [ModuleCellView cellWithNibName:@"ModuleCellView" bundle:nil reuseIdentifier:cellIdentifier];
		}
		cell.iconView.image = [UIImage imageNamed:@"Icons/icon17_04.png"];
		cell.titleLabel.text = @"Add Fleet Member";
		cell.stateView.image = nil;
		return cell;
	}
	else {
		NSString *cellIdentifier = @"FleetMemberCellView";
		FleetMemberCellView *cell = (FleetMemberCellView*) [aTableView dequeueReusableCellWithIdentifier:cellIdentifier];
		if (cell == nil) {
			cell = [FleetMemberCellView cellWithNibName:@"FleetMemberCellView" bundle:nil reuseIdentifier:cellIdentifier];
		}
		NSDictionary* row = [pilots objectAtIndex:indexPath.row];
		ItemInfo* ship = [row valueForKey:@"ship"];
		cell.titleLabel.text = [row valueForKey:@"title"];
		cell.fitNameLabel.text = [row valueForKey:@"fitName"];
		cell.iconView.image = [UIImage imageNamed:[ship typeSmallImageName]];
		if (fittingViewController.fit == [[pilots objectAtIndex:indexPath.row] valueForKey:@"fit"])
			cell.stateView.image = [UIImage imageNamed:@"checkmark.png"];
		else
			cell.stateView.image = nil;
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
	
	if (indexPath.row == pilots.count) {
		[fittingViewController addFleetMember];
	}
	else {
		UIActionSheet* actionSheet = [[[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil] autorelease];
		[actionSheet addButtonWithTitle:ActionButtonShowShipInfo];
		[actionSheet addButtonWithTitle:ActionButtonCharacter];
		Fit* fit = [[pilots objectAtIndex:indexPath.row] valueForKey:@"fit"];

		if (fit != self.fittingViewController.fit) {
			[actionSheet addButtonWithTitle:ActionButtonSelect];
		}
		
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
			eufe::Character* character = fit.character;
			eufe::Gang* gang = fittingViewController.fittingEngine->getGang();
			
			bool isBooster = false;
			if (gang->getFleetBooster() != character)
				[actionSheet addButtonWithTitle:ActionButtonSetFleetBooster];
			else
				isBooster = true;
			
			if (gang->getWingBooster() != character)
				[actionSheet addButtonWithTitle:ActionButtonSetWingBooster];
			else
				isBooster = true;
			
			if (gang->getSquadBooster() != character)
				[actionSheet addButtonWithTitle:ActionButtonSetSquadBooster];
			else
				isBooster = true;
			
			if (isBooster)
				[actionSheet addButtonWithTitle:ActionButtonRemoveBooster];
		}
		else
			[actionSheet addButtonWithTitle:ActionButtonBooster];

		if (indexPath.row > 0 && fit != fittingViewController.fit) {
			[actionSheet addButtonWithTitle:ActionButtonDelete];
			actionSheet.destructiveButtonIndex = actionSheet.numberOfButtons - 1;
		}
		
		[actionSheet addButtonWithTitle:ActionButtonCancel];
		actionSheet.cancelButtonIndex = actionSheet.numberOfButtons - 1;
		[actionSheet showFromRect:[aTableView rectForRowAtIndexPath:indexPath] inView:aTableView animated:YES];
		[modifiedIndexPath release];
		modifiedIndexPath = [indexPath retain];
	}
	
	
}

#pragma mark UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
	NSString *button = [actionSheet buttonTitleAtIndex:buttonIndex];
	if ([button isEqualToString:ActionButtonCharacter]) {
		Fit* fit = [[pilots objectAtIndex:modifiedIndexPath.row] valueForKey:@"fit"];
		[fittingViewController selectCharacterForFit:fit];
	}
	else if ([button isEqualToString:ActionButtonSelect]) {
		fittingViewController.fit = [[pilots objectAtIndex:modifiedIndexPath.row] valueForKey:@"fit"];
		[fittingViewController update];
	}
	else if ([button isEqualToString:ActionButtonDelete]) {
		Fit* fit = [[pilots objectAtIndex:modifiedIndexPath.row] valueForKey:@"fit"];
		[fittingViewController.fits removeObject:fit];
		fittingViewController.fittingEngine->getGang()->removePilot(fit.character);
		[fittingViewController update];
	}
	else if ([button isEqualToString:ActionButtonBooster]) {
		UIActionSheet* actionSheet = [[[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil] autorelease];
		Fit* fit = [[pilots objectAtIndex:modifiedIndexPath.row] valueForKey:@"fit"];
		eufe::Character* character = fit.character;
		eufe::Gang* gang = fittingViewController.fittingEngine->getGang();
		
		bool isBooster = false;
		if (gang->getFleetBooster() != character)
			[actionSheet addButtonWithTitle:ActionButtonSetFleetBooster];
		else
			isBooster = true;

		if (gang->getWingBooster() != character)
			[actionSheet addButtonWithTitle:ActionButtonSetWingBooster];
		else
			isBooster = true;

		if (gang->getSquadBooster() != character)
			[actionSheet addButtonWithTitle:ActionButtonSetSquadBooster];
		else
			isBooster = true;
		
		if (isBooster) {
			[actionSheet addButtonWithTitle:ActionButtonRemoveBooster];
			actionSheet.destructiveButtonIndex = actionSheet.numberOfButtons - 1;
		}
		
		[actionSheet addButtonWithTitle:ActionButtonCancel];
		actionSheet.cancelButtonIndex = actionSheet.numberOfButtons - 1;
		[actionSheet showFromRect:[tableView rectForRowAtIndexPath:modifiedIndexPath] inView:tableView animated:YES];
		
	}
	else if ([button isEqualToString:ActionButtonSetFleetBooster]) {
		Fit* fit = [[pilots objectAtIndex:modifiedIndexPath.row] valueForKey:@"fit"];
		fittingViewController.fittingEngine->getGang()->setFleetBooster(fit.character);
		[fittingViewController update];
	}
	else if ([button isEqualToString:ActionButtonSetWingBooster]) {
		Fit* fit = [[pilots objectAtIndex:modifiedIndexPath.row] valueForKey:@"fit"];
		fittingViewController.fittingEngine->getGang()->setWingBooster(fit.character);
		[fittingViewController update];
	}
	else if ([button isEqualToString:ActionButtonSetSquadBooster]) {
		Fit* fit = [[pilots objectAtIndex:modifiedIndexPath.row] valueForKey:@"fit"];
		fittingViewController.fittingEngine->getGang()->setSquadBooster(fit.character);
		[fittingViewController update];
	}
	else if ([button isEqualToString:ActionButtonRemoveBooster]) {
		Fit* fit = [[pilots objectAtIndex:modifiedIndexPath.row] valueForKey:@"fit"];
		eufe::Character* character = fit.character;
		eufe::Gang* gang = fittingViewController.fittingEngine->getGang();
		
		if (gang->getFleetBooster() == character)
			gang->removeFleetBooster();
		else if (gang->getWingBooster() == character)
			gang->removeWingBooster();
		else if (gang->getSquadBooster() == character)
			gang->removeSquadBooster();
		
		[fittingViewController update];
	}
	else if ([button isEqualToString:ActionButtonShowShipInfo]) {
		ItemInfo* itemInfo = [[pilots objectAtIndex:modifiedIndexPath.row] valueForKey:@"ship"];
		ItemViewController *itemViewController = [[ItemViewController alloc] initWithNibName:@"ItemViewController" bundle:nil];
		
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
	NSMutableArray* pilotsTmp = [NSMutableArray array];
	FittingViewController* aFittingViewController = fittingViewController;

	__block EUOperation *operation = [EUOperation operationWithIdentifier:@"ImplantsViewController+Update" name:@"Updating Fleet"];
	[operation addExecutionBlock:^(void) {
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		@synchronized(fittingViewController) {
			eufe::Gang* gang = aFittingViewController.fittingEngine->getGang();
			
			eufe::Character* fleetBooster = gang->getFleetBooster();
			eufe::Character* wingBooster = gang->getWingBooster();
			eufe::Character* squadBooster = gang->getSquadBooster();
			
			//for (i = characters.begin(); i != end; i++) {
			float n = fittingViewController.fits.count;
			float i = 0;
			for (Fit* fit in fittingViewController.fits) {
				operation.progress = i++ / n;
				eufe::Character* character = fit.character;
				ItemInfo* ship = [ItemInfo itemInfoWithItem:character->getShip() error:NULL];
				NSString *booster = nil;
				
				if (character == fleetBooster)
					booster = @" (Fleet Booster)";
				else if (character == wingBooster)
					booster = @" (Wing Booster)";
				else if (character == squadBooster)
					booster = @" (Squad Booster)";
				else
					booster = @"";
				
				NSMutableDictionary* row = [NSMutableDictionary dictionaryWithObjectsAndKeys:ship, @"ship",
											fit, @"fit",
											[NSString stringWithFormat:@"%@ - %s%@", ship.typeName, character->getCharacterName(), booster], @"title",
											fit.fitName ? fit.fitName : ship.typeName, @"fitName", nil];
				[pilotsTmp addObject:row];
			}
		}
		[pool release];
	}];
	
	[operation setCompletionBlockInCurrentThread:^(void) {
		if (![operation isCancelled]) {
			if (pilots)
				[pilots release];
			pilots = [pilotsTmp retain];
			[tableView reloadData];
		}
	}];
	
	[[EUOperationQueue sharedQueue] addOperation:operation];
}

@end
