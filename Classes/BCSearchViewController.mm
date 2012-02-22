//
//  BCSearchViewController.m
//  EVEUniverse
//
//  Created by Artem Shimanski on 5/14/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "BCSearchViewController.h"
#import "ItemCellView.h"
#import "NibTableViewCell.h"
#import "Globals.h"
#import "EVEDBAPI.h"
#import "TagCellView.h"
#import "BattleClinicAPI.h"
#import "Globals.h"
#import "UIAlertView+Error.h"
#import "BCSearchResultViewController.h"

@interface BCSearchViewController(Private)

- (void) testInputData;

@end


@implementation BCSearchViewController
@synthesize menuTableView;
@synthesize fittingItemsViewController;
@synthesize modalController;
@synthesize searchButton;
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


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
	NSMutableArray *tagsTmp = [NSMutableArray array];
	self.title = @"Search";
	[self.navigationItem setRightBarButtonItem:searchButton];
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		self.popoverController = [[[UIPopoverController alloc] initWithContentViewController:modalController] autorelease];
		self.popoverController.delegate = (FittingItemsViewController*)  self.modalController.topViewController;
	}

	selectedTags = [[NSMutableArray alloc] init];
	
	NSBlockOperation *operation = [NSBlockOperation blockOperationWithBlock:^(void) {
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		NSError *error = nil;
		BCEveLoadoutsTags *loadoutsTags = [BCEveLoadoutsTags eveLoadoutsTagsWithAPIKey:BattleClinicAPIKey error:&error];
		if (error) {
			[[UIAlertView alertViewWithError:error] performSelectorOnMainThread:@selector(show) withObject:nil waitUntilDone:NO];
		}
		else {
			[tagsTmp addObjectsFromArray:[loadoutsTags.tags sortedArrayUsingSelector:@selector(compare:)]];
		}
		[pool release];
	}];
	
	[operation setCompletionBlockInCurrentThread:^(void) {
		tags = [tagsTmp retain];
		[menuTableView insertSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationFade];
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

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc. that aren't in use.
}

- (void)viewDidUnload {
    [super viewDidUnload];
	self.menuTableView = nil;
	self.fittingItemsViewController = nil;
	self.modalController = nil;
	self.searchButton = nil;
	self.popoverController = nil;
	
	[tags release];
	[selectedTags release];
	tags = nil;
	selectedTags = nil;
}


- (void)dealloc {
	[menuTableView release];
	[fittingItemsViewController release];
	[modalController release];
	[searchButton release];
	[popoverController release];
	
	[ship release];
	[tags release];
	[selectedTags release];
    [super dealloc];
}

- (IBAction) didCloseModalViewController:(id) sender {
	[self dismissModalViewControllerAnimated:YES];
}

- (IBAction) onSearch:(id) sender {
	NSMutableArray *loadouts = [NSMutableArray array];
	
	__block EUSingleBlockOperation *operation = [EUSingleBlockOperation operationWithIdentifier:@"BCSearchViewController+Search"];
	[operation addExecutionBlock:^(void) {
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		NSError *error = nil;
		BCEveLoadoutsList *loadoutsList = [BCEveLoadoutsList eveLoadoutsListWithAPIKey:BattleClinicAPIKey raceID:0 typeID:ship.typeID classID:0 userID:0 tags:selectedTags error:&error];
		if (error) {
			[[UIAlertView alertViewWithError:error] performSelectorOnMainThread:@selector(show) withObject:nil waitUntilDone:NO];
		}
		else {
			if (loadoutsList.loadouts.count == 0) {
				UIAlertView *alertView = [[[UIAlertView alloc] initWithTitle:@"" message:@"Nothing found" delegate:nil cancelButtonTitle:@"Close" otherButtonTitles:nil] autorelease];
				[alertView performSelectorOnMainThread:@selector(show) withObject:nil waitUntilDone:NO];
			}
			else {
				[loadouts addObjectsFromArray:[loadoutsList.loadouts sortedArrayUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"thumbsTotal" ascending:NO]]]];
			}
		}
		[pool release];
	}];
	
	[operation setCompletionBlockInCurrentThread:^(void) {
		if (loadouts.count > 0 && ![operation isCancelled]) {
			BCSearchResultViewController *controller = [[BCSearchResultViewController alloc] initWithNibName:(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? @"BCSearchResultViewController-iPad" : @"BCSearchResultViewController")
																									  bundle:nil];
			controller.loadouts = loadouts;
			controller.ship = ship;
			[self.navigationController pushViewController:controller animated:YES];
			[controller release];
		}
	}];
	
	[[EUOperationQueue sharedQueue] addOperation:operation];
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
	return tags ? 2 : 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return section == 0 ? 1 : tags.count;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
		NSString *cellIdentifier = @"ItemCellView";
		
		ItemCellView *cell = (ItemCellView*) [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
		if (cell == nil) {
			cell = [ItemCellView cellWithNibName:@"ItemCellView" bundle:nil reuseIdentifier:cellIdentifier];
		}
		cell.accessoryType = UITableViewCellAccessoryNone;
		if (!ship) {
			cell.titleLabel.text = @"Select Ship";
			cell.iconImageView.image = [UIImage imageNamed:@"Icons/icon09_05.png"];
		}
		else {
			cell.titleLabel.text = ship.typeName;
			cell.iconImageView.image = [UIImage imageNamed:[ship typeSmallImageName]];
		}
		return cell;
	}
	else {
		NSString *cellIdentifier = @"TagCellView";
		
		TagCellView *cell = (TagCellView*) [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
		if (cell == nil) {
			cell = [TagCellView cellWithNibName:@"TagCellView" bundle:nil reuseIdentifier:cellIdentifier];
		}
		NSString *tag = [tags objectAtIndex:indexPath.row];
		cell.titleLabel.text = tag;
		//cell.accessoryType = [selectedTags containsObject:tag] ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
		cell.checkmarkImageView.image = [selectedTags containsObject:tag] ? [UIImage imageNamed:@"checkmark.png"] : nil;
		return cell;
	}
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	if (section == 0)
		return @"Ship";
	else
		return @"Tags";
}

#pragma mark -
#pragma mark Table view delegate

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
	UIView *header = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 22)] autorelease];
	header.opaque = NO;
	header.backgroundColor = [UIColor colorWithRed:0.3 green:0.3 blue:0.3 alpha:0.9];
	
	UILabel *label = [[[UILabel alloc] initWithFrame:CGRectMake(10, 0, 300, 22)] autorelease];
	label.opaque = NO;
	label.backgroundColor = [UIColor clearColor];
	label.text = [self tableView:tableView titleForHeaderInSection:section];
	label.textColor = [UIColor whiteColor];
	label.font = [label.font fontWithSize:12];
	label.shadowColor = [UIColor blackColor];
	label.shadowOffset = CGSizeMake(1, 1);
	[header addSubview:label];
	return header;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return 36;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	if (indexPath.section == 0) {
		fittingItemsViewController.groupsRequest = @"SELECT * FROM invGroups WHERE groupID IN (25,26,27,28,30,31,324,358,380,419,420,463,485,513,540,541,543,547,659,830,831,832,833,834,883,893,894,898,900,902,906,941,963,1022) ORDER BY groupName;";
//		fittingItemsViewController.typesRequest = @"SELECT * FROM invTypes WHERE published=1 AND groupID IN (25,26,27,28,30,31,324,358,380,419,420,463,485,513,540,541,543,547,659,830,831,832,833,834,883,893,894,898,900,902,906,941,963,1022) %@ %@ ORDER BY invTypes.typeName;";
		fittingItemsViewController.typesRequest = @"SELECT invMetaGroups.metaGroupID, invMetaGroups.metaGroupName, invTypes.* FROM invTypes LEFT JOIN invMetaTypes ON invMetaTypes.typeID=invTypes.typeID LEFT JOIN invMetaGroups ON invMetaTypes.metaGroupID=invMetaGroups.metaGroupID  WHERE invTypes.published=1 AND groupID IN (25,26,27,28,30,31,324,358,380,419,420,463,485,513,540,541,543,547,659,830,831,832,833,834,883,893,894,898,900,902,906,941,963,1022) %@ %@ ORDER BY invTypes.typeName";
		fittingItemsViewController.title = @"Ships";
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
			[popoverController presentPopoverFromRect:[tableView rectForRowAtIndexPath:indexPath] inView:tableView permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
		else
			[self presentModalViewController:modalController animated:YES];
	}
	else {
		NSString *tag = [tags objectAtIndex:indexPath.row];
		if ([selectedTags containsObject:tag])
			[selectedTags removeObject:tag];
		else
			[selectedTags addObject:tag];
		[tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
		[self testInputData];
	}
	return;
}

#pragma mark FittingItemsViewControllerDelegate

- (void) fittingItemsViewController:(FittingItemsViewController*) controller didSelectType:(EVEDBInvType*) type {
	[ship release];
	ship = [type retain];
	[self testInputData];
	[menuTableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationFade];

	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		[popoverController dismissPopoverAnimated:YES];
	else
		[self dismissModalViewControllerAnimated:YES];
}

@end

@implementation BCSearchViewController(Private)

- (void) testInputData {
	searchButton.enabled = ship && selectedTags.count > 0;
}

@end
