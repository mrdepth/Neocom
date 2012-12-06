//
//  ItemsDBViewController.m
//  EVEUniverse
//
//  Created by Artem Shimanski on 8/30/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "ItemsDBViewController.h"
#import "ItemInfoViewController.h"
#import "Globals.h"
#import "ItemCellView.h"
#import "UITableViewCell+Nib.h"
#import "ItemViewController.h"

@interface ItemsDBViewController(Private)
- (void) reload;
- (void) searchWithSearchString:(NSString*) aSearchString;
@end


@implementation ItemsDBViewController
@synthesize itemsTable;
@synthesize searchBar;
@synthesize publishedFilterSegment;
@synthesize category;
@synthesize group;
@synthesize rows;
@synthesize filteredValues;
@synthesize modalMode;

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
	[super viewDidLoad];
	self.rows = [NSMutableArray array];
	self.filteredValues = [NSMutableArray array];
	
	if (group)
		self.title = group.groupName;
	else if (category)
		self.title = category.categoryName;
	else
		self.title = @"Database";

	publishedFilterSegment.selectedSegmentIndex = [[NSUserDefaults standardUserDefaults] integerForKey:SettingsPublishedFilterKey];
	self.searchDisplayController.searchBar.selectedScopeButtonIndex = publishedFilterSegment.selectedSegmentIndex;
//	if (publishedFilterSegment.selectedSegmentIndex == 0)
		[self reload];
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad && !modalMode)
		[self.navigationItem setRightBarButtonItem:[[[UIBarButtonItem alloc] initWithCustomView:searchBar] autorelease]];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Overriden to allow any orientation.
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		return UIInterfaceOrientationIsLandscape(interfaceOrientation);
	else
		return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
}

- (void)viewDidUnload {
	[super viewDidUnload];
	self.itemsTable = nil;
	self.searchBar = nil;
	self.publishedFilterSegment = nil;
	self.rows = nil;
	self.filteredValues = nil;
}


- (void)dealloc {
	[itemsTable release];
	[searchBar release];
	[publishedFilterSegment release];
	[category release];
	[group release];
	[rows release];
	[filteredValues release];
	[super dealloc];
}

- (IBAction) onChangePublishedFilterSegment: (id) sender {
	[self reload];
	self.searchDisplayController.searchBar.selectedScopeButtonIndex = publishedFilterSegment.selectedSegmentIndex;
	[[NSUserDefaults standardUserDefaults] setInteger:publishedFilterSegment.selectedSegmentIndex forKey:SettingsPublishedFilterKey];
}

- (ItemsDBViewControllerMode) mode {
	if (publishedFilterSegment.selectedSegmentIndex == 0)
		return ItemsDBViewControllerModePublished;
	else if (publishedFilterSegment.selectedSegmentIndex == 2)
		return ItemsDBViewControllerModeNotPublished;
	else
		return ItemsDBViewControllerModeAll;
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	// Return the number of rows in the section.
	return self.searchDisplayController.searchResultsTableView == tableView ? filteredValues.count : rows.count;
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	static NSString *cellIdentifier = @"ItemCellView";
	
	ItemCellView *cell = (ItemCellView*) [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	if (cell == nil) {
		cell = [ItemCellView cellWithNibName:@"ItemCellView" bundle:nil reuseIdentifier:cellIdentifier];
	}
	if (self.searchDisplayController.searchResultsTableView == tableView) {
		EVEDBInvType *row = [self.filteredValues objectAtIndex:indexPath.row];
		cell.titleLabel.text = row.typeName;
		cell.iconImageView.image = [UIImage imageNamed:[row typeSmallImageName]];
	}
	else {
		if (category == nil) {
			EVEDBInvCategory *row = [rows objectAtIndex:indexPath.row];
			cell.titleLabel.text = [row categoryName];
			if (row.icon.iconImageName)
				cell.iconImageView.image = [UIImage imageNamed:row.icon.iconImageName];
			else
				cell.iconImageView.image = [UIImage imageNamed:@"Icons/icon38_174.png"];
		}
		else if (group == nil) {
			EVEDBInvGroup *row = [rows objectAtIndex:indexPath.row];
			cell.titleLabel.text = [row groupName];
			if (row.icon.iconImageName)
				cell.iconImageView.image = [UIImage imageNamed:row.icon.iconImageName];
			else
				cell.iconImageView.image = [UIImage imageNamed:@"Icons/icon38_174.png"];
		}
		else {
			EVEDBInvType *row = [rows objectAtIndex:indexPath.row];
			cell.titleLabel.text = row.typeName;
			cell.iconImageView.image = [UIImage imageNamed:[row typeSmallImageName]];
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

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return 36;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	if (self.searchDisplayController.searchResultsTableView == tableView) {
		ItemViewController *controller = [[ItemViewController alloc] initWithNibName:@"ItemViewController" bundle:nil];

		controller.type = [filteredValues objectAtIndex:indexPath.row];
		[controller setActivePage:ItemViewControllerActivePageInfo];

		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad && !modalMode) {
			UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:controller];
			navController.modalPresentationStyle = UIModalPresentationFormSheet;
			[self presentModalViewController:navController animated:YES];
			[navController release];
		}
		else
			[self.navigationController pushViewController:controller animated:YES];
		[controller release];
	}
	else if (category == nil) {
		ItemsDBViewController *controller = [[[self class] alloc] initWithNibName:self.nibName bundle:nil];
		controller.category = [rows objectAtIndex:indexPath.row];
		[self.navigationController pushViewController:controller animated:YES];
		[controller release];
	}
	else if (group == nil) {
		ItemsDBViewController *controller = [[[self class] alloc] initWithNibName:self.nibName bundle:nil];
		controller.category = self.category;
		controller.group = [rows objectAtIndex:indexPath.row];
		[self.navigationController pushViewController:controller animated:YES];
		[controller release];
	}
	else {
		ItemViewController *controller = [[ItemViewController alloc] initWithNibName:@"ItemViewController" bundle:nil];
		controller.type = [rows objectAtIndex:indexPath.row];
		[controller setActivePage:ItemViewControllerActivePageInfo];

		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad && !modalMode) {
			UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:controller];
			navController.modalPresentationStyle = UIModalPresentationFormSheet;
			[self presentModalViewController:navController animated:YES];
			[navController release];
		}
		else
			[self.navigationController pushViewController:controller animated:YES];
		[controller release];
	}
}

#pragma mark -
#pragma mark UISearchDisplayController Delegate Methods

- (BOOL) searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString {
	[self searchWithSearchString:searchString];
	return NO;
}


- (BOOL) searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchScope:(NSInteger)searchOption {
	[self searchWithSearchString:controller.searchBar.text];
	return NO;
}

- (void) searchBar:(UISearchBar *)searchBar selectedScopeButtonIndexDidChange:(NSInteger)selectedScope {
	publishedFilterSegment.selectedSegmentIndex = selectedScope;
	[[NSUserDefaults standardUserDefaults] setInteger:selectedScope forKey:SettingsPublishedFilterKey];
	[itemsTable reloadData];
}

- (void)searchDisplayController:(UISearchDisplayController *)controller didLoadSearchResultsTableView:(UITableView *)tableView {
	tableView.backgroundColor = [UIColor clearColor];
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		tableView.backgroundView = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:modalMode ? @"background3.png" : @"background4.png"]] autorelease];
		tableView.backgroundView.contentMode = UIViewContentModeTopLeft;
	}
	else {
		tableView.backgroundView = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"background1.png"]] autorelease];
		tableView.backgroundView.contentMode = UIViewContentModeTop;
	}
	tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
}

@end

@implementation ItemsDBViewController(Private)

- (void) reload {
	NSMutableArray *values = [NSMutableArray array];
	__block EUOperation *operation = [EUOperation operationWithIdentifier:@"ItemsDBViewController+Load" name:@"Loading..."];
	[operation addExecutionBlock:^(void) {
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		if (category == nil)
			[[EVEDBDatabase sharedDatabase] execWithSQLRequest:[NSString stringWithFormat:@"SELECT * FROM invCategories%@ ORDER BY categoryName;",
																self.mode == ItemsDBViewControllerModePublished ? @" WHERE published=1" :
																self.mode == ItemsDBViewControllerModeNotPublished ? @" WHERE published=0" : @""]
												   resultBlock:^(NSDictionary *record, BOOL *needsMore) {
													   [values addObject:[EVEDBInvCategory invCategoryWithDictionary:record]];
													   if ([operation isCancelled])
														   *needsMore = NO;
												   }];
		else if (group == nil)
			[[EVEDBDatabase sharedDatabase] execWithSQLRequest:[NSString stringWithFormat:@"SELECT * FROM invGroups WHERE categoryID=%d%@ ORDER BY groupName;", category.categoryID,
																self.mode == ItemsDBViewControllerModePublished ? @" AND published=1" :
																self.mode == ItemsDBViewControllerModeNotPublished ? @" AND published=0" : @""]
												   resultBlock:^(NSDictionary *record, BOOL *needsMore) {
													   [values addObject:[EVEDBInvGroup invGroupWithDictionary:record]];
													   if ([operation isCancelled])
														   *needsMore = NO;
												   }];
		else
			[[EVEDBDatabase sharedDatabase] execWithSQLRequest:[NSString stringWithFormat:@"SELECT * FROM invTypes WHERE groupID=%d%@ ORDER BY typeName;", group.groupID,
																self.mode == ItemsDBViewControllerModePublished ? @" AND published=1" :
																self.mode == ItemsDBViewControllerModeNotPublished ? @" AND published=0" : @""]
												   resultBlock:^(NSDictionary *record, BOOL *needsMore) {
													   [values addObject:[EVEDBInvType invTypeWithDictionary:record]];
													   if ([operation isCancelled])
														   *needsMore = NO;
												   }];
		[pool release];
	}];
	
	[operation setCompletionBlockInCurrentThread:^(void) {
		if (![operation isCancelled]) {
			self.rows = values;
			[self.itemsTable reloadData];
		}
	}];
	
	[[EUOperationQueue sharedQueue] addOperation:operation];
}

- (void) searchWithSearchString:(NSString*) aSearchString {
	NSString *searchString = [[aSearchString copy] autorelease];
	NSMutableArray *values = [NSMutableArray array];

	__block EUOperation *operation = [EUOperation operationWithIdentifier:@"ItemsDBViewController+Filter" name:@"Searching..."];
	[operation addExecutionBlock:^(void) {
		if ([operation isCancelled])
			return;
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		if (searchString.length >= 2) {
			EVEDBDatabaseResultBlock block = ^(NSDictionary *record, BOOL *needsMore) {
				[values addObject:[EVEDBInvType invTypeWithDictionary:record]];
				if ([operation isCancelled])
					*needsMore = NO;
			};
			
			if (group != nil)
				[[EVEDBDatabase sharedDatabase] execWithSQLRequest:[NSString stringWithFormat:@"SELECT * FROM invTypes WHERE groupID=%d AND typeName LIKE \"%%%@%%\"%@ ORDER BY typeName;",
																	group.groupID,
																	searchString,
																	self.mode == ItemsDBViewControllerModePublished ? @" AND published=1" :
																	self.mode == ItemsDBViewControllerModeNotPublished ? @" AND published=0" : @""]
													   resultBlock:block];
			else if (category != nil)
				[[EVEDBDatabase sharedDatabase] execWithSQLRequest:[NSString stringWithFormat:@"SELECT invTypes.* FROM invTypes, invGroups WHERE invGroups.categoryID=%d AND invTypes.groupID=invGroups.groupID AND typeName LIKE \"%%%@%%\"%@ ORDER BY typeName;",
																	category.categoryID,
																	searchString,
																	self.mode == ItemsDBViewControllerModePublished ? @" AND invTypes.published=1" :
																	self.mode == ItemsDBViewControllerModeNotPublished ? @" AND invTypes.published=0" : @""]
													   resultBlock:block];
			else
				[[EVEDBDatabase sharedDatabase] execWithSQLRequest:[NSString stringWithFormat:@"SELECT * FROM invTypes WHERE typeName LIKE \"%%%@%%\"%@ ORDER BY typeName;",
																	searchString,
																	self.mode == ItemsDBViewControllerModePublished ? @" AND published=1" :
																	self.mode == ItemsDBViewControllerModeNotPublished ? @" AND published=0" : @""]
													   resultBlock:block];
		}
		[pool release];
	}];
	
	[operation setCompletionBlockInCurrentThread:^(void) {
		if (![operation isCancelled]) {
			self.filteredValues = values;
			[self.searchDisplayController.searchResultsTableView reloadData];
		}
	}];
	
	[[EUOperationQueue sharedQueue] addOperation:operation];
}

@end