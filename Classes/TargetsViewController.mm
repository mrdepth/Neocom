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
#import "ShipFit.h"
#import "ItemInfo.h"

#include "eufe.h"

@interface TargetsViewController()
@property (nonatomic, strong) NSArray* targets;

@end

@implementation TargetsViewController

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
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		self.tableView.backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"backgroundPopover~ipad.png"]];
		self.tableView.backgroundView.contentMode = UIViewContentModeTop;
	}
	else
		self.tableView.backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"background.png"]];
	self.title = @"Select Target";
    // Do any additional setup after loading the view from its nib.
}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		return YES;
	else
		return UIInterfaceOrientationIsPortrait(toInterfaceOrientation);
}

- (void)viewDidUnload
{
    [super viewDidUnload];
	self.targets = nil;
}

- (void) viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	
	NSMutableArray* targetsTmp = [NSMutableArray array];
	__block EUOperation *operation = [EUOperation operationWithIdentifier:@"TargetsViewController+Update" name:NSLocalizedString(@"Loading Targets", nil)];
	__weak EUOperation* weakOperation = operation;
	[operation addExecutionBlock:^(void) {
		eufe::Gang* gang = self.fittingViewController.fittingEngine->getGang();
		
		eufe::Character* fleetBooster = gang->getFleetBooster();
		eufe::Character* wingBooster = gang->getWingBooster();
		eufe::Character* squadBooster = gang->getSquadBooster();
		
		//for (i = characters.begin(); i != end; i++) {
		float n = self.fittingViewController.fits.count;
		float i = 0;
		for (ShipFit* fit in self.fittingViewController.fits) {
			weakOperation.progress = i++ / n;
			if (fit == self.fittingViewController.fit)
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
	}];
	
	[operation setCompletionBlockInMainThread:^(void) {
		if (![weakOperation isCancelled]) {
			self.targets = targetsTmp;
			[self.tableView reloadData];
		}
	}];
	
	[[EUOperationQueue sharedQueue] addOperation:operation];
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return self.targets.count;
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	NSString *cellIdentifier = @"FleetMemberCellView";
	FleetMemberCellView *cell = (FleetMemberCellView*) [aTableView dequeueReusableCellWithIdentifier:cellIdentifier];
	if (cell == nil) {
		cell = [FleetMemberCellView cellWithNibName:@"FleetMemberCellView" bundle:nil reuseIdentifier:cellIdentifier];
	}
	NSDictionary* row = [self.targets objectAtIndex:indexPath.row];
	ItemInfo* ship = [row valueForKey:@"ship"];
	ShipFit* fit = [[self.targets objectAtIndex:indexPath.row] valueForKey:@"fit"];

	cell.titleLabel.text = [row valueForKey:@"title"];
	cell.fitNameLabel.text = [row valueForKey:@"fitName"];
	cell.iconView.image = [UIImage imageNamed:[ship typeSmallImageName]];
	if (self.currentTarget == fit.character->getShip())
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
	ShipFit* fit = [[self.targets objectAtIndex:indexPath.row] valueForKey:@"fit"];
	[self.delegate targetsViewController:self didSelectTarget:fit.character->getShip()];
}

#pragma mark UIPopoverControllerDelegate

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController {
	popoverController.popoverContentSize = CGSizeMake(320, 1100);
}

@end
