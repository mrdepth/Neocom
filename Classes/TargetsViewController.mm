//
//  TargetsViewController.m
//  EVEUniverse
//
//  Created by mr_depth on 02.01.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "TargetsViewController.h"
#import "FittingViewController.h"
#import "EUOperationQueue.h"
#import "ShipFit.h"
#import "ItemInfo.h"
#import "GroupedCell.h"
#import "appearance.h"

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
	self.view.backgroundColor = [UIColor colorWithNumber:AppearanceBackgroundColor];
	self.title = NSLocalizedString(@"Select Target", nil);
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
		self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Close", nil)
																				 style:UIBarButtonItemStyleBordered
																				target:self
																				action:@selector(dismiss)];
    // Do any additional setup after loading the view from its nib.
}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		return YES;
	else
		return UIInterfaceOrientationIsPortrait(toInterfaceOrientation);
}

- (void) viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	
	NSMutableArray* targetsTmp = [NSMutableArray array];
	EUOperation *operation = [EUOperation operationWithIdentifier:@"TargetsViewController+Update" name:NSLocalizedString(@"Loading Targets", nil)];
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

- (void) viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	self.completionHandler = nil;
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
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *cellIdentifier = @"Cell";
	GroupedCell *cell = (GroupedCell*) [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	if (cell == nil) {
		cell = [[GroupedCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
	}
	NSDictionary* row = self.targets[indexPath.row];
	ItemInfo* ship = row[@"ship"];
	ShipFit* fit = row[@"fit"];

	cell.textLabel.text = [row valueForKey:@"title"];
	cell.detailTextLabel.text = [row valueForKey:@"fitName"];
	cell.imageView.image = [UIImage imageNamed:[ship typeSmallImageName]];
	cell.accessoryView = self.currentTarget == fit.character->getShip() ? [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"checkmark.png"]] : nil;
	
	int groupStyle = 0;
	if (indexPath.row == 0)
		groupStyle |= GroupedCellGroupStyleTop;
	if (indexPath.row == [self tableView:tableView numberOfRowsInSection:indexPath.section] - 1)
		groupStyle |= GroupedCellGroupStyleBottom;
	cell.groupStyle = static_cast<GroupedCellGroupStyle>(groupStyle);
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
	self.completionHandler(fit.character->getShip());
	self.completionHandler = nil;
}

#pragma mark UIPopoverControllerDelegate

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController {
	popoverController.popoverContentSize = CGSizeMake(320, 1100);
}

@end
