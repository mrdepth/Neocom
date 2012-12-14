//
//  TargetsViewController.m
//  EVEUniverse
//
//  Created by mr_depth on 02.01.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "TargetsViewController.h"
#import "FittingViewController.h"
#import "FleetMemberCellView.h"
#import "UITableViewCell+Nib.h"
#import "EUOperationQueue.h"
#import "Fit.h"
#import "ItemInfo.h"

#include "eufe.h"

@implementation TargetsViewController
@synthesize tableView;
@synthesize fittingViewController;
@synthesize currentTarget;
@synthesize delegate;
@synthesize modifiedItem;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	self.title = @"Select Target";
    // Do any additional setup after loading the view from its nib.
}

- (void)viewDidUnload
{
    [super viewDidUnload];
	[self setTableView:nil];
	[targets release];
	targets = nil;
}

- (void) viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	
	NSMutableArray* targetsTmp = [NSMutableArray array];
	__block EUOperation *operation = [EUOperation operationWithIdentifier:@"TargetsViewController+Update" name:NSLocalizedString(@"Loading Targets", nil)];
	[operation addExecutionBlock:^(void) {
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		eufe::Gang* gang = fittingViewController.fittingEngine->getGang();
		
		eufe::Character* fleetBooster = gang->getFleetBooster();
		eufe::Character* wingBooster = gang->getWingBooster();
		eufe::Character* squadBooster = gang->getSquadBooster();
		
		//for (i = characters.begin(); i != end; i++) {
		float n = fittingViewController.fits.count;
		float i = 0;
		for (Fit* fit in fittingViewController.fits) {
			operation.progress = i++ / n;
			if (fit == fittingViewController.fit)
				continue;
			
			eufe::Character* character = fit.character;
			ItemInfo* ship = [ItemInfo itemInfoWithItem:character->getShip() error:NULL];
			NSString *booster = nil;
			
			if (character == fleetBooster)
				booster = NSLocalizedString(@" (Fleet Booster)", nil);
			else if (character == wingBooster)
				booster = NSLocalizedString(@" (Wing Booster)", nil);
			else if (character == squadBooster)
				booster = NSLocalizedString(@" (Squad Booster)", nil);
			else
				booster = @"";
			
			NSMutableDictionary* row = [NSMutableDictionary dictionaryWithObjectsAndKeys:ship, @"ship",
										fit, @"fit",
										[NSString stringWithFormat:@"%@ - %s%@", ship.typeName, character->getCharacterName(), booster], @"title",
										fit.fitName ? fit.fitName : ship.typeName, @"fitName", nil];
			[targetsTmp addObject:row];
		}
		[pool release];
	}];
	
	[operation setCompletionBlockInCurrentThread:^(void) {
		if (![operation isCancelled]) {
			if (targets)
				[targets release];
			targets = [targetsTmp retain];
			[tableView reloadData];
		}
	}];
	
	[[EUOperationQueue sharedQueue] addOperation:operation];
}

// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		return UIInterfaceOrientationIsLandscape(interfaceOrientation);
	else
		return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)dealloc {
	[tableView release];
	[targets release];
	[modifiedItem release];
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
    return targets.count;
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	NSString *cellIdentifier = @"FleetMemberCellView";
	FleetMemberCellView *cell = (FleetMemberCellView*) [aTableView dequeueReusableCellWithIdentifier:cellIdentifier];
	if (cell == nil) {
		cell = [FleetMemberCellView cellWithNibName:@"FleetMemberCellView" bundle:nil reuseIdentifier:cellIdentifier];
	}
	NSDictionary* row = [targets objectAtIndex:indexPath.row];
	ItemInfo* ship = [row valueForKey:@"ship"];
	Fit* fit = [[targets objectAtIndex:indexPath.row] valueForKey:@"fit"];

	cell.titleLabel.text = [row valueForKey:@"title"];
	cell.fitNameLabel.text = [row valueForKey:@"fitName"];
	cell.iconView.image = [UIImage imageNamed:[ship typeSmallImageName]];
	if (currentTarget == fit.character->getShip())
		cell.stateView.image = [UIImage imageNamed:@"Icons/icon04_12.png"];
	else
		cell.stateView.image = nil;
	return cell;
}


#pragma mark -
#pragma mark Table view delegate

- (CGFloat)tableView:(UITableView *)aTableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return [[self tableView:aTableView cellForRowAtIndexPath:indexPath] frame].size.height;
}

- (void)tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[aTableView deselectRowAtIndexPath:indexPath animated:YES];
	Fit* fit = [[targets objectAtIndex:indexPath.row] valueForKey:@"fit"];
	[delegate targetsViewController:self didSelectTarget:fit.character->getShip()];
}

#pragma mark UIPopoverControllerDelegate

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController {
	popoverController.popoverContentSize = CGSizeMake(320, 1100);
}

@end
