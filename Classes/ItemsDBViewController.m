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
#import "UITableViewCell+Nib.h"
#import "ItemViewController.h"
#import "appearance.h"
#import "GroupedCell.h"
#import "UIActionSheet+Block.h"

@interface ItemsDBViewController()
@property (nonatomic, strong) UIBarButtonItem* publishedButton;
@property (nonatomic, strong) UIActionSheet* actionSheet;


- (void) reload;
- (void) searchWithSearchString:(NSString*) aSearchString;
- (NSString*) localizedPublishedTitleWithMode:(ItemsDBViewControllerMode) mode;
@end


@implementation ItemsDBViewController
// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
	[super viewDidLoad];
	
	self.tableView.backgroundColor = [UIColor colorWithNumber:AppearanceBackgroundColor];
	self.rows = [NSMutableArray array];
	self.filteredValues = [NSMutableArray array];
	
	if (self.group)
		self.title = self.group.groupName;
	else if (self.category)
		self.title = self.category.categoryName;
	else
		self.title = NSLocalizedString(@"Database", nil);

	self.mode = [[NSUserDefaults standardUserDefaults] integerForKey:SettingsPublishedFilterKey];
	self.searchDisplayController.searchBar.selectedScopeButtonIndex = self.mode;
	[self reload];
	
	
	self.publishedButton = [[UIBarButtonItem alloc] initWithTitle:[self localizedPublishedTitleWithMode:self.mode]
															style:UIBarButtonItemStyleBordered
														   target:self
														   action:@selector(onChangePublished:)];
	
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
		//self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.publishedFilterSegment];
		self.tableView.tableHeaderView = self.searchBar;
		//self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.searchBar];
		self.navigationItem.rightBarButtonItem = self.publishedButton;
	}
	else if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {// && !self.modalMode) {
		//[self.navigationItem setRightBarButtonItem:[[UIBarButtonItem alloc] initWithCustomView:self.searchBar]];
		self.navigationItem.rightBarButtonItems = @[self.publishedButton, [[UIBarButtonItem alloc] initWithCustomView:self.searchBar]];
//		self.tableView.tableHeaderView = self.pu
	}
}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		return YES;
	else
		return UIInterfaceOrientationIsPortrait(toInterfaceOrientation);
}

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
	if ([self isViewLoaded] && [self.view window] == nil) {
		self.view = nil;
		self.searchBar = nil;
		self.rows = nil;
		self.filteredValues = nil;
	}
}


- (IBAction) onChangePublished: (id) sender {
	[self.actionSheet dismissWithClickedButtonIndex:self.actionSheet.cancelButtonIndex animated:NO];
	self.actionSheet = [UIActionSheet actionSheetWithTitle:nil
										 cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
									destructiveButtonTitle:nil
										 otherButtonTitles:@[NSLocalizedString(@"Published", nil), NSLocalizedString(@"Unpublished", nil), NSLocalizedString(@"All", nil)]
										   completionBlock:^(UIActionSheet *actionSheet, NSInteger selectedButtonIndex) {
											   if (selectedButtonIndex != actionSheet.cancelButtonIndex) {
												   self.mode = selectedButtonIndex;
												   self.searchDisplayController.searchBar.selectedScopeButtonIndex = self.mode;
												   [[NSUserDefaults standardUserDefaults] setInteger:self.mode forKey:SettingsPublishedFilterKey];
												   [self reload];
											   }
										   } cancelBlock:nil];
	[self.actionSheet showFromBarButtonItem:sender animated:YES];
}

- (void) setMode:(ItemsDBViewControllerMode)mode {
	_mode = mode;
	self.publishedButton.title = [self localizedPublishedTitleWithMode:_mode];
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
	
	static NSString *cellIdentifier = @"Cell";
	
	GroupedCell* cell = (GroupedCell*) [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	if (cell == nil) {
		cell = [[GroupedCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];//[ItemCellView cellWithNibName:@"ItemCellView" bundle:nil reuseIdentifier:cellIdentifier];
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	}
	if (self.searchDisplayController.searchResultsTableView == tableView) {
		EVEDBInvType *row = [self.filteredValues objectAtIndex:indexPath.row];
		cell.textLabel.text = row.typeName;
		cell.imageView.image = [UIImage imageNamed:[row typeSmallImageName]];
	}
	else {
		if (self.category == nil) {
			EVEDBInvCategory *row = [self.rows objectAtIndex:indexPath.row];
			cell.textLabel.text = [row categoryName];
			if (row.icon.iconImageName)
				cell.imageView.image = [UIImage imageNamed:row.icon.iconImageName];
			else
				cell.imageView.image = [UIImage imageNamed:@"Icons/icon38_174.png"];
		}
		else if (self.group == nil) {
			EVEDBInvGroup *row = [self.rows objectAtIndex:indexPath.row];
			cell.textLabel.text = [row groupName];
			if (row.icon.iconImageName)
				cell.imageView.image = [UIImage imageNamed:row.icon.iconImageName];
			else
				cell.imageView.image = [UIImage imageNamed:@"Icons/icon38_174.png"];
		}
		else {
			EVEDBInvType *row = [self.rows objectAtIndex:indexPath.row];
			cell.textLabel.text = row.typeName;
			cell.imageView.image = [UIImage imageNamed:[row typeSmallImageName]];
		}
	}
	
/*	if (cell.iconImageView.image.size.width < cell.iconImageView.frame.size.width)
		cell.iconImageView.contentMode = UIViewContentModeCenter;
	else
		cell.iconImageView.contentMode = UIViewContentModeScaleAspectFit;*/

	GroupedCellGroupStyle groupStyle = 0;
	if (indexPath.row == 0)
		groupStyle |= GroupedCellGroupStyleTop;
	if (indexPath.row == [self tableView:tableView numberOfRowsInSection:indexPath.section] - 1)
		groupStyle |= GroupedCellGroupStyleBottom;
	cell.groupStyle = groupStyle;
	return cell;
}

#pragma mark -
#pragma mark Table view delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return 40;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	if (self.searchDisplayController.searchResultsTableView == tableView) {
		ItemViewController *controller = [[ItemViewController alloc] initWithNibName:@"ItemViewController" bundle:nil];

		controller.type = [self.filteredValues objectAtIndex:indexPath.row];
		[controller setActivePage:ItemViewControllerActivePageInfo];

		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad && !self.modalMode) {
			UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:controller];
			navController.modalPresentationStyle = UIModalPresentationFormSheet;
			[self presentViewController:navController animated:YES completion:nil];
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
			[self presentViewController:navController animated:YES completion:nil];
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
	self.mode = selectedScope;
	[[NSUserDefaults standardUserDefaults] setInteger:selectedScope forKey:SettingsPublishedFilterKey];
	[self.tableView reloadData];
}

- (void)searchDisplayController:(UISearchDisplayController *)controller didLoadSearchResultsTableView:(UITableView *)tableView {
	tableView.backgroundView = nil;
	tableView.backgroundColor = [UIColor colorWithNumber:AppearanceBackgroundColor];
}

- (void) searchDisplayControllerDidBeginSearch:(UISearchDisplayController *)controller {
	[self.searchBar invalidateIntrinsicContentSize];
	[self.searchBar setShowsScopeBar:YES];
}

- (void) searchDisplayControllerDidEndSearch:(UISearchDisplayController *)controller {
	[self.searchBar setShowsScopeBar:NO];
	[self.searchBar invalidateIntrinsicContentSize];
}

#pragma mark - Private

- (void) reload {
	NSMutableArray *values = [NSMutableArray array];
	EUOperation *operation = [EUOperation operationWithIdentifier:@"ItemsDBViewController+Load" name:NSLocalizedString(@"Loading...", nil)];
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
	
	[operation setCompletionBlockInMainThread:^(void) {
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

	EUOperation *operation = [EUOperation operationWithIdentifier:@"ItemsDBViewController+Filter" name:NSLocalizedString(@"Searching...", nil)];
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
	
	[operation setCompletionBlockInMainThread:^(void) {
		if (![weakOperation isCancelled]) {
			self.filteredValues = values;
			[self.searchDisplayController.searchResultsTableView reloadData];
		}
	}];
	
	[[EUOperationQueue sharedQueue] addOperation:operation];
}

- (NSString*) localizedPublishedTitleWithMode:(ItemsDBViewControllerMode) mode {
	if (mode == ItemsDBViewControllerModePublished)
		return NSLocalizedString(@"Published", nil);
	else if (mode == ItemsDBViewControllerModeAll)
		return NSLocalizedString(@"All", nil);
	else
		return NSLocalizedString(@"Unpublished", nil);
}

@end