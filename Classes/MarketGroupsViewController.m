//
//  MarketGroupsViewController.m
//  EVEUniverse
//
//  Created by Artem Shimanski on 9/1/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "MarketGroupsViewController.h"
#import "ItemInfoViewController.h"
#import "ItemViewController.h"
#import "ItemCellView.h"
#import "UITableViewCell+Nib.h"
#import "Globals.h"
#import "CollapsableTableHeaderView.h"
#import "UIView+Nib.h"

@interface MarketGroupsViewController()

- (void) reload;
- (void) searchWithSearchString:(NSString*) aSearchString;

@end


@implementation MarketGroupsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
	self.tableView.backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"background.png"]];

	if (!self.parentGroup)
		self.title = NSLocalizedString(@"Market", nil);
	else
		self.title = self.parentGroup.marketGroupName;
	[self reload];
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		[self.navigationItem setRightBarButtonItem:[[UIBarButtonItem alloc] initWithCustomView:self.searchBar]];
	else
		self.tableView.tableHeaderView = self.searchBar;
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
	self.parentGroup = nil;
	self.subGroups = nil;
	self.groupItems = nil;
	self.filteredValues = nil;
}


#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
	if (self.searchDisplayController.searchResultsTableView == tableView)
		return self.filteredValues.count;
	else {
		if (self.groupItems)
			return self.groupItems.count;
		else
			return 1;
	}
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
	if (self.searchDisplayController.searchResultsTableView == tableView) {
		return [[[self.filteredValues objectAtIndex:section] valueForKey:@"rows"] count];
	}
	else {
		if (self.groupItems)
			return [[[self.groupItems objectAtIndex:section] valueForKey:@"rows"] count];
		else
			return self.subGroups.count;
	}
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *cellIdentifier = @"ItemCellView";
    
    ItemCellView *cell = (ItemCellView*) [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [ItemCellView cellWithNibName:@"ItemCellView" bundle:nil reuseIdentifier:cellIdentifier];
    }
	if (self.searchDisplayController.searchResultsTableView == tableView) {
		EVEDBInvType *row = [[[self.filteredValues objectAtIndex:indexPath.section] valueForKey:@"rows"] objectAtIndex:indexPath.row];
		cell.titleLabel.text = row.typeName;
		cell.iconImageView.image = [UIImage imageNamed:[row typeSmallImageName]];
	}
	else {
		if (self.groupItems) {
			EVEDBInvType *row = [[[self.groupItems objectAtIndex:indexPath.section] valueForKey:@"rows"] objectAtIndex:indexPath.row];
			cell.titleLabel.text = row.typeName;
			cell.iconImageView.image = [UIImage imageNamed:[row typeSmallImageName]];
		}
		else {
			EVEDBInvMarketGroup *row = [self.subGroups objectAtIndex:indexPath.row];
			cell.titleLabel.text = row.marketGroupName;
			if (row.icon.iconImageName)
				cell.iconImageView.image = [UIImage imageNamed:row.icon.iconImageName];
			else
				cell.iconImageView.image = [UIImage imageNamed:@"Icons/icon38_174.png"];
		}
	}
    
	if (cell.iconImageView.image.size.width < cell.iconImageView.frame.size.width)
		cell.iconImageView.contentMode = UIViewContentModeCenter;
	else
		cell.iconImageView.contentMode = UIViewContentModeScaleAspectFit;
    
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	if (self.searchDisplayController.searchResultsTableView == tableView) {
		return [[self.filteredValues objectAtIndex:section] valueForKey:@"title"];
	}
	else {
		if (self.groupItems)
			return [[self.groupItems objectAtIndex:section] valueForKey:@"title"];
		else
			return nil;
	}
}

#pragma mark -
#pragma mark Table view delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return 36;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	if (self.searchDisplayController.searchResultsTableView == tableView) {
		ItemViewController *controller = [[ItemViewController alloc] initWithNibName:@"ItemViewController" bundle:nil];
		
		controller.type = [[[self.filteredValues objectAtIndex:indexPath.section] valueForKey:@"rows"] objectAtIndex:indexPath.row];
		[controller setActivePage:ItemViewControllerActivePageMarket];
		
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
			UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:controller];
			navController.modalPresentationStyle = UIModalPresentationFormSheet;
			[self presentModalViewController:navController animated:YES];
		}
		else
			[self.navigationController pushViewController:controller animated:YES];
	}
	else if (self.groupItems) {
		ItemViewController *controller = [[ItemViewController alloc] initWithNibName:@"ItemViewController" bundle:nil];
		controller.type = [[[self.groupItems objectAtIndex:indexPath.section] valueForKey:@"rows"] objectAtIndex:indexPath.row];
		[controller setActivePage:ItemViewControllerActivePageMarket];
		
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
			UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:controller];
			navController.modalPresentationStyle = UIModalPresentationFormSheet;
			[self presentModalViewController:navController animated:YES];
		}
		else
			[self.navigationController pushViewController:controller animated:YES];
	}
	else {
		MarketGroupsViewController *controller = [[MarketGroupsViewController alloc] initWithNibName:@"MarketGroupsViewController" bundle:nil];
		controller.parentGroup = [self.subGroups objectAtIndex:indexPath.row];
		[self.navigationController pushViewController:controller animated:YES];
	}
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
	NSString* title = [self tableView:tableView titleForHeaderInSection:section];
	CollapsableTableHeaderView* view = [CollapsableTableHeaderView viewWithNibName:@"CollapsableTableHeaderView" bundle:nil];
	view.collapsed = NO;
	view.titleLabel.text = title;
	if (tableView == self.searchDisplayController.searchResultsTableView || !self.groupItems)
		view.collapsImageView.hidden = YES;
	else
		view.collapsed = [self tableView:tableView sectionIsCollapsed:section];
	return view;
}

#pragma mark - CollapsableTableViewDelegate

- (BOOL) tableView:(UITableView *)tableView sectionIsCollapsed:(NSInteger) section {
	if (self.groupItems)
		return [[[self.groupItems objectAtIndex:section] valueForKey:@"collapsed"] boolValue];
	else
		return NO;
}

- (BOOL) tableView:(UITableView *)tableView canCollapsSection:(NSInteger) section {
	return self.groupItems ? YES : NO;
}

- (void) tableView:(UITableView *)tableView didCollapsSection:(NSInteger) section {
	if (self.groupItems)
		[[self.groupItems objectAtIndex:section] setValue:@(YES) forKey:@"collapsed"];
}

- (void) tableView:(UITableView *)tableView didExpandSection:(NSInteger) section {
	if (self.groupItems)
		[[self.groupItems objectAtIndex:section] setValue:@(NO) forKey:@"collapsed"];
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

- (void)searchDisplayController:(UISearchDisplayController *)controller didLoadSearchResultsTableView:(UITableView *)tableView {
	tableView.backgroundColor = [UIColor clearColor];
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		tableView.backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"backgroundPopover~ipad.png"]];
		tableView.backgroundView.contentMode = UIViewContentModeTop;
	}
	else
		tableView.backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"background.png"]];
	
	tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
}

#pragma mark - Private

- (void) reload {
	NSMutableArray *subGroupValues = [NSMutableArray array];
	NSMutableArray *itemValues = [NSMutableArray array];
	__block EUOperation *operation = [EUOperation operationWithIdentifier:@"MarketGroupsViewController+Load" name:NSLocalizedString(@"Loading...", nil)];
	__weak EUOperation* weakOperation = operation;
	
	[operation addExecutionBlock:^(void) {
		if (self.parentGroup == nil) {
			[[EVEDBDatabase sharedDatabase] execSQLRequest:@"SELECT * FROM invMarketGroups WHERE parentGroupID IS NULL ORDER BY marketGroupName;"
											   resultBlock:^(sqlite3_stmt *stmt, BOOL *needsMore) {
												   [subGroupValues addObject:[[EVEDBInvMarketGroup alloc] initWithStatement:stmt]];
												   if ([weakOperation isCancelled])
													   *needsMore = NO;
											   }];
			[[EVEDBDatabase sharedDatabase] execSQLRequest:@"SELECT * FROM invMarketGroups WHERE parentGroupID IS NULL ORDER BY marketGroupName;"
												   resultBlock:^(sqlite3_stmt *stmt, BOOL *needsMore) {
													   [subGroupValues addObject:[[EVEDBInvMarketGroup alloc] initWithStatement:stmt]];
													   if ([weakOperation isCancelled])
														   *needsMore = NO;
												   }];
		}
		else {
			[[EVEDBDatabase sharedDatabase] execSQLRequest:[NSString stringWithFormat:@"SELECT * FROM invMarketGroups WHERE parentGroupID=%d ORDER BY marketGroupName;", self.parentGroup.marketGroupID]
												   resultBlock:^(sqlite3_stmt *stmt, BOOL *needsMore) {
													   [subGroupValues addObject:[[EVEDBInvMarketGroup alloc] initWithStatement:stmt]];
													   if ([weakOperation isCancelled])
														   *needsMore = NO;
												   }];
			if (subGroupValues.count == 0) {
				NSMutableDictionary* sections = [NSMutableDictionary dictionary];
				[[EVEDBDatabase sharedDatabase] execSQLRequest:[NSString stringWithFormat:@"SELECT c.*, a.* from invTypes AS a LEFT JOIN invMetaTypes AS b ON a.typeID=b.typeID LEFT JOIN invMetaGroups AS c ON b.metaGroupID=c.metaGroupID LEFT JOIN dgmTypeAttributes AS d ON d.typeID=a.typeID AND d.attributeID=633 WHERE marketGroupID = %d ORDER BY d.value, typeName;", self.parentGroup.marketGroupID]
													   resultBlock:^(sqlite3_stmt *stmt, BOOL *needsMore) {
														   EVEDBInvType* type = [[EVEDBInvType alloc] initWithStatement:stmt];
														   int metaGroupID = sqlite3_column_int(stmt, 1);
														   NSNumber* key = @(metaGroupID);
														   NSMutableDictionary* section = [sections objectForKey:key];
														   if (!section) {
															   const char* metaGroupName = (const char*) sqlite3_column_text(stmt, 0);
															   NSString* title = metaGroupName ? [NSString stringWithCString:metaGroupName encoding:NSUTF8StringEncoding] : @"";
															   
															   section = [NSMutableDictionary dictionaryWithObjectsAndKeys:
																		  title, @"title",
																		  [NSMutableArray arrayWithObject:type], @"rows",
																		  key, @"order", nil];
															   [sections setObject:section forKey:key];
														   }
														   else
															   [[section valueForKey:@"rows"] addObject:type];
														   
														   if ([weakOperation isCancelled])
															   *needsMore = NO;
													   }];
				[itemValues addObjectsFromArray:[[sections allValues] sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"order" ascending:YES]]]];
			}
		}
	}];
	
	[operation setCompletionBlockInCurrentThread:^(void) {
		if (![weakOperation isCancelled]) {
			self.subGroups = subGroupValues;
			if (itemValues.count > 0)
				self.groupItems = itemValues;
			[self.tableView reloadData];
		}
	}];
	
	[[EUOperationQueue sharedQueue] addOperation:operation];
}


- (void) searchWithSearchString:(NSString*) aSearchString {
	NSString *searchString = [aSearchString copy];
	NSMutableArray *values = [NSMutableArray array];
	
	__block EUOperation *operation = [EUOperation operationWithIdentifier:@"MarketGroupsViewController+Filter" name:NSLocalizedString(@"Searching...", nil)];
	__weak EUOperation* weakOperation = operation;
	[operation addExecutionBlock:^(void) {
		if ([weakOperation isCancelled])
			return;
		if (searchString.length >= 2) {
			NSMutableDictionary* sections = [NSMutableDictionary dictionary];
			[[EVEDBDatabase sharedDatabase] execSQLRequest:[NSString stringWithFormat:@"SELECT c.*, a.* from invTypes AS a LEFT JOIN invMetaTypes AS b ON a.typeID=b.typeID LEFT JOIN invMetaGroups AS c ON b.metaGroupID=c.metaGroupID LEFT JOIN dgmTypeAttributes AS d ON d.typeID=a.typeID AND d.attributeID=633 WHERE typeName LIKE \"%%%@%%\" AND marketGroupID > 0 ORDER BY d.value, typeName;", searchString]
												   resultBlock:^(sqlite3_stmt *stmt, BOOL *needsMore) {
													   EVEDBInvType* type = [[EVEDBInvType alloc] initWithStatement:stmt];
													   int metaGroupID = sqlite3_column_int(stmt, 1);
													   NSNumber* key = metaGroupID > 0 ? @(metaGroupID) : @(INT_MAX);
													   NSMutableDictionary* section = [sections objectForKey:key];
													   if (!section) {
														   const char* metaGroupName = (const char*) sqlite3_column_text(stmt, 0);
														   NSString* title = metaGroupName ? [NSString stringWithCString:metaGroupName encoding:NSUTF8StringEncoding] : @"";
														   
														   section = [NSMutableDictionary dictionaryWithObjectsAndKeys:
																	  title, @"title",
																	  [NSMutableArray arrayWithObject:type], @"rows",
																	  key, @"order", nil];
														   [sections setObject:section forKey:key];
													   }
													   else
														   [[section valueForKey:@"rows"] addObject:type];
													   
													   if ([weakOperation isCancelled])
														   *needsMore = NO;
												   }];
			[values addObjectsFromArray:[[sections allValues] sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"order" ascending:YES]]]];
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
