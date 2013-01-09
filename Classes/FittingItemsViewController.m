//
//  FittingItemsViewController.m
//  EVEUniverse
//
//  Created by Artem Shimanski on 5/8/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "FittingItemsViewController.h"
#import "EVEDBAPI.h"
#import "ItemCellView.h"
#import "UITableViewCell+Nib.h"
#import "Globals.h"
#import "ItemViewController.h"

@interface FittingItemsViewController(Private)
- (void) reload;
- (void) searchWithSearchString:(NSString*) aSearchString;
@end

@implementation FittingItemsViewController
@synthesize tableView;
@synthesize mainViewController;
@synthesize groupsRequest;
@synthesize typesRequest;
@synthesize group;
@synthesize delegate;
@synthesize modifiedItem;


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
	filteredSections = [[NSMutableArray alloc] init];
	needsReload = YES;
}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		return YES;
	else
		return UIInterfaceOrientationIsPortrait(toInterfaceOrientation);
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc. that aren't in use.
}

- (void)viewDidUnload {
    [super viewDidUnload];
	self.tableView = nil;
	[sections release];
	sections = nil;
	[filteredSections release];
	filteredSections = nil;
}

- (void) viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	if (needsReload)
		[self reload];
}

- (void)dealloc {
	[tableView release];
	[groupsRequest release];
	[typesRequest release];
	[group release];
	[sections release];
	[filteredSections release];
	[modifiedItem release];
    [super dealloc];
}

- (void) setGroupsRequest:(NSString *)value {
	if ([groupsRequest isEqualToString:value])
		return;
	[value retain];
	[groupsRequest release];
	groupsRequest = value;
	[self.navigationController popToRootViewControllerAnimated:NO];
	needsReload = YES;
	self.group = nil;
}

- (void) setTypesRequest:(NSString *)value {
	if ([typesRequest isEqualToString:value])
		return;
	[value retain];
	[typesRequest release];
	typesRequest = value;
	[self.navigationController popToRootViewControllerAnimated:NO];
	needsReload = YES;
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)aTableView {
    // Return the number of sections.
	return self.searchDisplayController.searchResultsTableView == aTableView ? filteredSections.count : sections.count;
}

- (NSString *)tableView:(UITableView *)aTableView titleForHeaderInSection:(NSInteger)section {
	return self.searchDisplayController.searchResultsTableView == aTableView ? [[filteredSections objectAtIndex:section] valueForKey:@"title"] : [[sections objectAtIndex:section] valueForKey:@"title"];
}

- (NSInteger)tableView:(UITableView *)aTableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
	return self.searchDisplayController.searchResultsTableView == aTableView ? [[[filteredSections objectAtIndex:section] valueForKey:@"rows"] count] : [[[sections objectAtIndex:section] valueForKey:@"rows"] count];
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *cellIdentifier = @"ItemCellView";
    
    ItemCellView *cell = (ItemCellView*) [aTableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [ItemCellView cellWithNibName:@"ItemCellView" bundle:nil reuseIdentifier:cellIdentifier];
    }
	if (self.searchDisplayController.searchResultsTableView == aTableView) {
		EVEDBInvType *row = [[[filteredSections objectAtIndex:indexPath.section] valueForKey:@"rows"] objectAtIndex:indexPath.row];
		cell.titleLabel.text = row.typeName;
		cell.iconImageView.image = [UIImage imageNamed:[row typeSmallImageName]];
		cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
	}
	else {
		if (group == nil) {
			EVEDBInvGroup *row = [[[sections objectAtIndex:indexPath.section] valueForKey:@"rows"] objectAtIndex:indexPath.row];
			cell.titleLabel.text = [row groupName];
			if (row.icon.iconImageName)
				cell.iconImageView.image = [UIImage imageNamed:row.icon.iconImageName];
			else
				cell.iconImageView.image = [UIImage imageNamed:@"Icons/icon38_174.png"];
			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		}
		else {
			EVEDBInvType *row = [[[sections objectAtIndex:indexPath.section] valueForKey:@"rows"] objectAtIndex:indexPath.row];
			cell.titleLabel.text = row.typeName;
			cell.iconImageView.image = [UIImage imageNamed:[row typeSmallImageName]];
			cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
		}
	}
	
	if (cell.iconImageView.image.size.width < cell.iconImageView.frame.size.width)
		cell.iconImageView.contentMode = UIViewContentModeCenter;
	else
		cell.iconImageView.contentMode = UIViewContentModeScaleAspectFit;
	
    return cell;
}

#pragma mark -
#pragma mark Table view delegate

- (UIView *)tableView:(UITableView *)aTableView viewForHeaderInSection:(NSInteger)section {
	NSString *s = [self tableView:aTableView titleForHeaderInSection:section];
	UIView *header = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 22)] autorelease];
	header.opaque = NO;
	header.backgroundColor = [UIColor colorWithRed:0.3 green:0.3 blue:0.3 alpha:0.9];
	
	UILabel *label = [[[UILabel alloc] initWithFrame:CGRectMake(10, 0, 300, 22)] autorelease];
	label.opaque = NO;
	label.backgroundColor = [UIColor clearColor];
	label.text = s;
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

- (void)tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	if (self.searchDisplayController.searchResultsTableView == aTableView) {
		EVEDBInvType *row = [[[filteredSections objectAtIndex:indexPath.section] valueForKey:@"rows"] objectAtIndex:indexPath.row];
		[delegate fittingItemsViewController:self didSelectType:row];
	}
	else if (!group) {
		FittingItemsViewController *controller = [[FittingItemsViewController alloc] initWithNibName:@"FittingItemsViewController" bundle:nil];
		controller.groupsRequest = self.groupsRequest;
		controller.group = self.searchDisplayController.searchResultsTableView == aTableView ?
		[[[filteredSections objectAtIndex:indexPath.section] valueForKey:@"rows"] objectAtIndex:indexPath.row] :
		[[[sections objectAtIndex:indexPath.section] valueForKey:@"rows"] objectAtIndex:indexPath.row];
		controller.typesRequest = self.typesRequest;
		controller.title = controller.group.groupName;
		controller.delegate = self;
		controller.mainViewController = self.mainViewController;
		[self.navigationController pushViewController:controller animated:YES];
		[controller release];
	}
	else {
		EVEDBInvType *row = [[[sections objectAtIndex:indexPath.section] valueForKey:@"rows"] objectAtIndex:indexPath.row];
		[delegate fittingItemsViewController:self didSelectType:row];
	}
}

- (void)tableView:(UITableView *)aTableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
	EVEDBInvType *row;
	if (self.searchDisplayController.searchResultsTableView == aTableView)
		row = [[[filteredSections objectAtIndex:indexPath.section] valueForKey:@"rows"] objectAtIndex:indexPath.row];
	else
		row = [[[sections objectAtIndex:indexPath.section] valueForKey:@"rows"] objectAtIndex:indexPath.row];
	
	ItemViewController *controller = [[ItemViewController alloc] initWithNibName:@"ItemViewController" bundle:nil];
	
	controller.type = row;
	[controller setActivePage:ItemViewControllerActivePageInfo];
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:controller];
		navController.modalPresentationStyle = UIModalPresentationFormSheet;
		[mainViewController presentModalViewController:navController animated:YES];
		[navController release];
	}
	else
		[self.navigationController pushViewController:controller animated:YES];
	[controller release];
}

#pragma mark -
#pragma mark UISearchDisplayController Delegate Methods

- (BOOL) searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString {
	//[self filter];
	[self searchWithSearchString:searchString];
    return NO;
}


- (void)searchDisplayController:(UISearchDisplayController *)controller didLoadSearchResultsTableView:(UITableView *)aTableView {
	aTableView.backgroundColor = [UIColor clearColor];
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		aTableView.backgroundView = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"background4.png"]] autorelease];
		aTableView.backgroundView.contentMode = UIViewContentModeTopLeft;
	}
	else {
		aTableView.backgroundView = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"background1.png"]] autorelease];
		aTableView.backgroundView.contentMode = UIViewContentModeTop;
	}
	aTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
}

#pragma mark FittingItemsViewControllerDelegate

- (void) fittingItemsViewController:(FittingItemsViewController*) controller didSelectType:(EVEDBInvType*) type {
	[delegate fittingItemsViewController:self didSelectType:type];
}

#pragma mark UIPopoverControllerDelegate

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController {
	popoverController.popoverContentSize = CGSizeMake(320, 1100);
}

@end


@implementation FittingItemsViewController(Private)

- (void) reload {
	[self.searchDisplayController setActive:NO];
	[filteredSections release];
	filteredSections = nil;
	[sections release];
	sections = nil;
	[tableView scrollsToTop];
	
	NSMutableArray *groups = [NSMutableArray array];
	NSMutableArray *sectionsTmp = [NSMutableArray array];

	__block EUOperation *operation = [EUOperation operationWithIdentifier:@"FittingItemsViewController+Load" name:NSLocalizedString(@"Loading...", nil)];
	[operation addExecutionBlock:^(void) {
		if ([operation isCancelled])
			return;
		
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		NSMutableDictionary *sectionsDic = [NSMutableDictionary dictionary];
		
		if (!group)
			[[EVEDBDatabase sharedDatabase] execWithSQLRequest:groupsRequest
												   resultBlock:^(NSDictionary *record, BOOL *needsMore){
													   [groups addObject:[EVEDBInvGroup invGroupWithDictionary:record]];
													   if ([operation isCancelled])
														   *needsMore = NO;
												   }];
		else
			[[EVEDBDatabase sharedDatabase] execWithSQLRequest:[NSString stringWithFormat:typesRequest, [NSString stringWithFormat:@"AND invTypes.groupID=%d", group.groupID], @""]
												   resultBlock:^(NSDictionary *record, BOOL *needsMore){
													   
													   NSString *metaGroupName = [record valueForKey:@"metaGroupName"];
													   NSInteger metaGroupID = metaGroupName ? [[record valueForKey:@"metaGroupID"] integerValue] : 1;
													   if (metaGroupName == nil)
														   metaGroupName = @"Tech I";
													   NSDictionary *section = [sectionsDic valueForKey:metaGroupName];
													   if (!section) {
														   section = [NSDictionary dictionaryWithObjectsAndKeys:[NSMutableArray array], @"rows",
																	  [NSString stringWithFormat:@"%d", metaGroupID], @"metaGroupID",
																	  metaGroupName, @"title",
																	  nil];
														   [sectionsDic setValue:section forKey:metaGroupName ? metaGroupName : @"default"];
													   }
													   NSMutableArray *sectionsRows = [section valueForKey:@"rows"];
													   [sectionsRows addObject:[EVEDBInvType invTypeWithDictionary:record]];
													   if ([operation isCancelled])
														   *needsMore = NO;
												   }];
		operation.progress = 0.75;
		[sectionsTmp addObjectsFromArray:[[sectionsDic allValues] sortedArrayUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"metaGroupID" ascending:YES]]]];
		[pool release];
	}];
	
	[operation setCompletionBlockInCurrentThread:^(void) {
		if (![operation isCancelled]) {
			[sections release];
			if (!group)
				sections = [[NSMutableArray arrayWithObject:[NSDictionary dictionaryWithObjectsAndKeys:groups, @"rows", nil]] retain];
			else
				sections = [sectionsTmp retain];
			[self.tableView reloadData];
		}
	}];
	
	[[EUOperationQueue sharedQueue] addOperation:operation];
	needsReload = NO;
}

- (void) searchWithSearchString:(NSString*) aSearchString {
	NSString *searchString = [[aSearchString copy] autorelease];
	NSMutableArray *filteredValues = [NSMutableArray array];
	
	__block EUOperation *operation = [EUOperation operationWithIdentifier:@"FittingItemsViewController+Filter" name:NSLocalizedString(@"Searching...", nil)];
	[operation addExecutionBlock:^(void) {
		if ([operation isCancelled] || searchString.length < 2)
			return;
		
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		NSMutableDictionary *sectionsDic = [NSMutableDictionary dictionary];
		
		EVEDBDatabaseResultBlock block = ^(NSDictionary *record, BOOL *needsMore) {
			NSString *metaGroupName = [record valueForKey:@"metaGroupName"];
			NSInteger metaGroupID = metaGroupName ? [[record valueForKey:@"metaGroupID"] integerValue] : 1;
			if (metaGroupName == nil)
				metaGroupName = @"Tech I";
			NSDictionary *section = [sectionsDic valueForKey:metaGroupName];
			if (!section) {
				section = [NSDictionary dictionaryWithObjectsAndKeys:[NSMutableArray array], @"rows",
						   [NSNumber numberWithInteger:metaGroupID], @"metaGroupID",
						   metaGroupName, @"title",
						   nil];
				[sectionsDic setValue:section forKey:metaGroupName ? metaGroupName : @"default"];
			}
			NSMutableArray *sectionsRows = [section valueForKey:@"rows"];
			[sectionsRows addObject:[EVEDBInvType invTypeWithDictionary:record]];
			if ([operation isCancelled])
				*needsMore = NO;
		};
		
		if (group != nil)
			[[EVEDBDatabase sharedDatabase] execWithSQLRequest:[NSString stringWithFormat:typesRequest, [NSString stringWithFormat:@"AND invTypes.groupID=%d", group.groupID],
																[NSString stringWithFormat:@"AND typeName LIKE \"%%%@%%\"", searchString]]
												   resultBlock:block];
		else
			[[EVEDBDatabase sharedDatabase] execWithSQLRequest:[NSString stringWithFormat:typesRequest, @"",
																[NSString stringWithFormat:@"AND typeName LIKE \"%%%@%%\"", searchString]]
												   resultBlock:block];
		[filteredValues addObjectsFromArray:[[sectionsDic allValues] sortedArrayUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"metaGroupID" ascending:YES]]]];
		[pool release];
	}];
	
	[operation setCompletionBlockInCurrentThread:^(void) {
		if (![operation isCancelled]) {
			[filteredSections release];
			filteredSections = [filteredValues retain];
			[self.searchDisplayController.searchResultsTableView reloadData];
		}
	}];
	
	[[EUOperationQueue sharedQueue] addOperation:operation];
}

@end