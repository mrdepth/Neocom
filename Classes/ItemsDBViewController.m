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

@interface ItemsDBViewController()
- (void) reload;
- (void) searchWithSearchString:(NSString*) aSearchString;
@end


@implementation ItemsDBViewController

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
	[super viewDidLoad];
	self.tableView.backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"background.png"]];
	self.rows = [NSMutableArray array];
	self.filteredValues = [NSMutableArray array];
	
	if (self.group)
		self.title = self.group.groupName;
	else if (self.category)
		self.title = self.category.categoryName;
	else
		self.title = NSLocalizedString(@"Database", nil);

	self.publishedFilterSegment.selectedSegmentIndex = [[NSUserDefaults standardUserDefaults] integerForKey:SettingsPublishedFilterKey];
	self.searchDisplayController.searchBar.selectedScopeButtonIndex = self.publishedFilterSegment.selectedSegmentIndex;
//	if (publishedFilterSegment.selectedSegmentIndex == 0)
		[self reload];
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad && !self.modalMode)
		[self.navigationItem setRightBarButtonItem:[[UIBarButtonItem alloc] initWithCustomView:self.searchBar]];
}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		return YES;
	else
		return UIInterfaceOrientationIsPortrait(toInterfaceOrientation);
}

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
}

- (void)viewDidUnload {
	[super viewDidUnload];
	self.searchBar = nil;
	self.publishedFilterSegment = nil;
	self.rows = nil;
	self.filteredValues = nil;
}


- (IBAction) onChangePublishedFilterSegment: (id) sender {
	[self reload];
	self.searchDisplayController.searchBar.selectedScopeButtonIndex = self.publishedFilterSegment.selectedSegmentIndex;
	[[NSUserDefaults standardUserDefaults] setInteger:self.publishedFilterSegment.selectedSegmentIndex forKey:SettingsPublishedFilterKey];
}

- (ItemsDBViewControllerMode) mode {
	if (self.publishedFilterSegment.selectedSegmentIndex == 0)
		return ItemsDBViewControllerModePublished;
	else if (self.publishedFilterSegment.selectedSegmentIndex == 2)
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
	return self.searchDisplayController.searchResultsTableView == tableView ? self.filteredValues.count : self.rows.count;
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
		if (self.category == nil) {
			EVEDBInvCategory *row = [self.rows objectAtIndex:indexPath.row];
			cell.titleLabel.text = [row categoryName];
			if (row.icon.iconImageName)
				cell.iconImageView.image = [UIImage imageNamed:row.icon.iconImageName];
			else
				cell.iconImageView.image = [UIImage imageNamed:@"Icons/icon38_174.png"];
		}
		else if (self.group == nil) {
			EVEDBInvGroup *row = [self.rows objectAtIndex:indexPath.row];
			cell.titleLabel.text = [row groupName];
			if (row.icon.iconImageName)
				cell.iconImageView.image = [UIImage imageNamed:row.icon.iconImageName];
			else
				cell.iconImageView.image = [UIImage imageNamed:@"Icons/icon38_174.png"];
		}
		else {
			EVEDBInvType *row = [self.rows objectAtIndex:indexPath.row];
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

		controller.type = [self.filteredValues objectAtIndex:indexPath.row];
		[controller setActivePage:ItemViewControllerActivePageInfo];

		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad && !self.modalMode) {
			UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:controller];
			navController.modalPresentationStyle = UIModalPresentationFormSheet;
			[self presentModalViewController:navController animated:YES];
		}
		else
			[self.navigationController pushViewController:controller animated:YES];
	}
	else if (self.category == nil) {
		ItemsDBViewController *controller = [[[self class] alloc] initWithNibName:self.nibName bundle:nil];
		controller.category = [self.rows objectAtIndex:indexPath.row];
		[self.navigationController pushViewController:controller animated:YES];
	}
	else if (self.group == nil) {
		ItemsDBViewController *controller = [[[self class] alloc] initWithNibName:self.nibName bundle:nil];
		controller.category = self.category;
		controller.group = [self.rows objectAtIndex:indexPath.row];
		[self.navigationController pushViewController:controller animated:YES];
	}
	else {
		ItemViewController *controller = [[ItemViewController alloc] initWithNibName:@"ItemViewController" bundle:nil];
		controller.type = [self.rows objectAtIndex:indexPath.row];
		[controller setActivePage:ItemViewControllerActivePageInfo];

		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad && !self.modalMode) {
			UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:controller];
			navController.modalPresentationStyle = UIModalPresentationFormSheet;
			[self presentModalViewController:navController animated:YES];
		}
		else
			[self.navigationController pushViewController:controller animated:YES];
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
	self.publishedFilterSegment.selectedSegmentIndex = selectedScope;
	[[NSUserDefaults standardUserDefaults] setInteger:selectedScope forKey:SettingsPublishedFilterKey];
	[self.tableView reloadData];
}

- (void)searchDisplayController:(UISearchDisplayController *)controller didLoadSearchResultsTableView:(UITableView *)tableView {
	tableView.backgroundColor = [UIColor clearColor];
	
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		tableView.backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:self.modalMode ? @"background.png" : @"backgroundPopover~ipad.png"]];
		tableView.backgroundView.contentMode = UIViewContentModeTopLeft;
	}
	else
		tableView.backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"background.png"]];
	
	tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
}

#pragma mark - Private

- (void) reload {
	NSMutableArray *values = [NSMutableArray array];
	__block EUOperation *operation = [EUOperation operationWithIdentifier:@"ItemsDBViewController+Load" name:NSLocalizedString(@"Loading...", nil)];
	__weak EUOperation* weakOperation = operation;
	[operation addExecutionBlock:^(void) {
		if (self.category == nil)
			[[EVEDBDatabase sharedDatabase] execSQLRequest:[NSString stringWithFormat:@"SELECT * FROM invCategories%@ ORDER BY categoryName;",
															self.mode == ItemsDBViewControllerModePublished ? @" WHERE published=1" :
															self.mode == ItemsDBViewControllerModeNotPublished ? @" WHERE published=0" : @""]
											   resultBlock:^(sqlite3_stmt *stmt, BOOL *needsMore) {
												   [values addObject:[[EVEDBInvCategory alloc] initWithStatement:stmt]];
												   if ([weakOperation isCancelled])
													   *needsMore = NO;
											   }];
		else if (self.group == nil)
			[[EVEDBDatabase sharedDatabase] execSQLRequest:[NSString stringWithFormat:@"SELECT * FROM invGroups WHERE categoryID=%d%@ ORDER BY groupName;", self.category.categoryID,
															self.mode == ItemsDBViewControllerModePublished ? @" AND published=1" :
															self.mode == ItemsDBViewControllerModeNotPublished ? @" AND published=0" : @""]
											   resultBlock:^(sqlite3_stmt *stmt, BOOL *needsMore) {
												   [values addObject:[[EVEDBInvGroup alloc] initWithStatement:stmt]];
												   if ([weakOperation isCancelled])
													   *needsMore = NO;
											   }];
		else
			[[EVEDBDatabase sharedDatabase] execSQLRequest:[NSString stringWithFormat:@"SELECT * FROM invTypes WHERE groupID=%d%@ ORDER BY typeName;", self.group.groupID,
															self.mode == ItemsDBViewControllerModePublished ? @" AND published=1" :
															self.mode == ItemsDBViewControllerModeNotPublished ? @" AND published=0" : @""]
											   resultBlock:^(sqlite3_stmt *stmt, BOOL *needsMore) {
												   [values addObject:[[EVEDBInvType alloc] initWithStatement:stmt]];
												   if ([weakOperation isCancelled])
													   *needsMore = NO;
											   }];
	}];
	
	[operation setCompletionBlockInCurrentThread:^(void) {
		if (![weakOperation isCancelled]) {
			self.rows = values;
			[self.tableView reloadData];
			if (self.searchBar.text.length > 0)
				[self searchWithSearchString:self.searchBar.text];
		}
	}];
	
	[[EUOperationQueue sharedQueue] addOperation:operation];
}

- (void) searchWithSearchString:(NSString*) aSearchString {
	NSString *searchString = [aSearchString copy];
	NSMutableArray *values = [NSMutableArray array];

	__block EUOperation *operation = [EUOperation operationWithIdentifier:@"ItemsDBViewController+Filter" name:NSLocalizedString(@"Searching...", nil)];
	__weak EUOperation* weakOperation = operation;
	[operation addExecutionBlock:^(void) {
		if ([weakOperation isCancelled])
			return;
		if (searchString.length >= 2) {
			void (^block)(sqlite3_stmt* stmt, BOOL *needsMore) = ^(sqlite3_stmt* stmt, BOOL *needsMore) {
				[values addObject:[[EVEDBInvType alloc] initWithStatement:stmt]];
				if ([weakOperation isCancelled])
					*needsMore = NO;
			};
			
			if (self.group != nil)
				[[EVEDBDatabase sharedDatabase] execSQLRequest:[NSString stringWithFormat:@"SELECT * FROM invTypes WHERE groupID=%d AND typeName LIKE \"%%%@%%\"%@ ORDER BY typeName;",
																self.group.groupID,
																searchString,
																self.mode == ItemsDBViewControllerModePublished ? @" AND published=1" :
																self.mode == ItemsDBViewControllerModeNotPublished ? @" AND published=0" : @""]
												   resultBlock:block];
			else if (self.category != nil)
				[[EVEDBDatabase sharedDatabase] execSQLRequest:[NSString stringWithFormat:@"SELECT invTypes.* FROM invTypes, invGroups WHERE invGroups.categoryID=%d AND invTypes.groupID=invGroups.groupID AND typeName LIKE \"%%%@%%\"%@ ORDER BY typeName;",
																self.category.categoryID,
																searchString,
																self.mode == ItemsDBViewControllerModePublished ? @" AND invTypes.published=1" :
																self.mode == ItemsDBViewControllerModeNotPublished ? @" AND invTypes.published=0" : @""]
												   resultBlock:block];
			else
				[[EVEDBDatabase sharedDatabase] execSQLRequest:[NSString stringWithFormat:@"SELECT * FROM invTypes WHERE typeName LIKE \"%%%@%%\"%@ ORDER BY typeName;",
																searchString,
																self.mode == ItemsDBViewControllerModePublished ? @" AND published=1" :
																self.mode == ItemsDBViewControllerModeNotPublished ? @" AND published=0" : @""]
												   resultBlock:block];
		}
	}];
	
	[operation setCompletionBlockInCurrentThread:^(void) {
		if (![weakOperation isCancelled]) {
			self.filteredValues = values;
			[self.searchDisplayController.searchResultsTableView reloadData];
		}
	}];
	
	[[EUOperationQueue sharedQueue] addOperation:operation];
}

@end