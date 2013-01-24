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

@interface MarketGroupsViewController(Private)

- (void) reload;
- (void) searchWithSearchString:(NSString*) aSearchString;

@end


@implementation MarketGroupsViewController
@synthesize itemsTable;
@synthesize searchBar;
@synthesize parentGroup;
@synthesize subGroups;
@synthesize groupItems;
@synthesize filteredValues;

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
	if (!parentGroup)
		self.title = NSLocalizedString(@"Market", nil);
	else
		self.title = parentGroup.marketGroupName;
	[self reload];
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		[self.navigationItem setRightBarButtonItem:[[[UIBarButtonItem alloc] initWithCustomView:searchBar] autorelease]];
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
	self.itemsTable = nil;
	self.searchBar = nil;
	self.parentGroup = nil;
	self.subGroups = nil;
	self.groupItems = nil;
	self.filteredValues = nil;
}


- (void)dealloc {
	[itemsTable release];
	[searchBar release];
	[parentGroup release];
	[subGroups release];
	[groupItems release];
	[filteredValues release];
    [super dealloc];
}


#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
	if (self.searchDisplayController.searchResultsTableView == tableView)
		return filteredValues.count;
	else {
		if (self.groupItems)
			return groupItems.count;
		else
			return 1;
	}
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
	if (self.searchDisplayController.searchResultsTableView == tableView) {
		return [[[filteredValues objectAtIndex:section] valueForKey:@"rows"] count];
	}
	else {
		if (self.groupItems)
			return [[[groupItems objectAtIndex:section] valueForKey:@"rows"] count];
		else
			return subGroups.count;
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
			EVEDBInvType *row = [[[groupItems objectAtIndex:indexPath.section] valueForKey:@"rows"] objectAtIndex:indexPath.row];
			cell.titleLabel.text = row.typeName;
			cell.iconImageView.image = [UIImage imageNamed:[row typeSmallImageName]];
		}
		else {
			EVEDBInvMarketGroup *row = [subGroups objectAtIndex:indexPath.row];
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
		
		controller.type = [[[filteredValues objectAtIndex:indexPath.section] valueForKey:@"rows"] objectAtIndex:indexPath.row];
		[controller setActivePage:ItemViewControllerActivePageMarket];
		
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
			UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:controller];
			navController.modalPresentationStyle = UIModalPresentationFormSheet;
			[self presentModalViewController:navController animated:YES];
			[navController release];
		}
		else
			[self.navigationController pushViewController:controller animated:YES];
		[controller release];
	}
	else if (self.groupItems) {
		ItemViewController *controller = [[ItemViewController alloc] initWithNibName:@"ItemViewController" bundle:nil];
		controller.type = [[[groupItems objectAtIndex:indexPath.section] valueForKey:@"rows"] objectAtIndex:indexPath.row];
		[controller setActivePage:ItemViewControllerActivePageMarket];
		
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
			UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:controller];
			navController.modalPresentationStyle = UIModalPresentationFormSheet;
			[self presentModalViewController:navController animated:YES];
			[navController release];
		}
		else
			[self.navigationController pushViewController:controller animated:YES];
		[controller release];
	}
	else {
		MarketGroupsViewController *controller = [[MarketGroupsViewController alloc] initWithNibName:@"MarketGroupsViewController" bundle:nil];
		controller.parentGroup = [subGroups objectAtIndex:indexPath.row];
		[self.navigationController pushViewController:controller animated:YES];
		[controller release];
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
		return [[[groupItems objectAtIndex:section] valueForKey:@"collapsed"] boolValue];
	else
		return NO;
}

- (BOOL) tableView:(UITableView *)tableView canCollapsSection:(NSInteger) section {
	return self.groupItems ? YES : NO;
}

- (void) tableView:(UITableView *)tableView didCollapsSection:(NSInteger) section {
	if (self.groupItems)
		[[groupItems objectAtIndex:section] setValue:@(YES) forKey:@"collapsed"];
}

- (void) tableView:(UITableView *)tableView didExpandSection:(NSInteger) section {
	if (self.groupItems)
		[[groupItems objectAtIndex:section] setValue:@(NO) forKey:@"collapsed"];
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
		tableView.backgroundView = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"background4.png"]] autorelease];	
		tableView.backgroundView.contentMode = UIViewContentModeTopLeft;
	}
	else {
		tableView.backgroundView = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"background1.png"]] autorelease];
		tableView.backgroundView.contentMode = UIViewContentModeTop;
	}
	tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
}
@end

@implementation MarketGroupsViewController(Private)

- (void) reload {
	NSMutableArray *subGroupValues = [NSMutableArray array];
	NSMutableArray *itemValues = [NSMutableArray array];
	__block EUOperation *operation = [EUOperation operationWithIdentifier:@"MarketGroupsViewController+Load" name:NSLocalizedString(@"Loading...", nil)];
	[operation addExecutionBlock:^(void) {
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		if (parentGroup == nil) {
			[[EVEDBDatabase sharedDatabase] execWithSQLRequest:@"SELECT * FROM invMarketGroups WHERE parentGroupID IS NULL ORDER BY marketGroupName;"
												   resultBlock:^(NSDictionary *record, BOOL *needsMore) {
													   [subGroupValues addObject:[EVEDBInvMarketGroup invMarketGroupWithDictionary:record]];
													   if ([operation isCancelled])
														   *needsMore = NO;
												   }];
		}
		else {
			[[EVEDBDatabase sharedDatabase] execWithSQLRequest:[NSString stringWithFormat:@"SELECT * FROM invMarketGroups WHERE parentGroupID=%d ORDER BY marketGroupName;", parentGroup.marketGroupID]
												   resultBlock:^(NSDictionary *record, BOOL *needsMore) {
													   [subGroupValues addObject:[EVEDBInvMarketGroup invMarketGroupWithDictionary:record]];
													   if ([operation isCancelled])
														   *needsMore = NO;
												   }];
			if (subGroupValues.count == 0) {
				NSMutableDictionary* sections = [NSMutableDictionary dictionary];
				[[EVEDBDatabase sharedDatabase] execWithSQLRequest:[NSString stringWithFormat:@"SELECT a.*, c.metaGroupName, c.metaGroupID from invTypes AS a LEFT JOIN invMetaTypes AS b ON a.typeID=b.typeID LEFT JOIN invMetaGroups AS c ON b.metaGroupID=c.metaGroupID LEFT JOIN dgmTypeAttributes AS d ON d.typeID=a.typeID AND d.attributeID=633 WHERE marketGroupID = %d ORDER BY d.value, typeName;", parentGroup.marketGroupID]
													   resultBlock:^(NSDictionary *record, BOOL *needsMore) {
														   EVEDBInvType* type = [EVEDBInvType invTypeWithDictionary:record];
														   NSString* key = [record valueForKey:@"metaGroupID"];
														   if (!key)
															   key = @"0";
														   NSMutableDictionary* section = [sections valueForKey:key];
														   if (!section) {
															   NSString* title = [record valueForKey:@"metaGroupName"];
															   if (!title)
																   title = @"";
															   
															   section = [NSMutableDictionary dictionaryWithObjectsAndKeys:
																		  title, @"title",
																		  [NSMutableArray arrayWithObject:type], @"rows",
																		  key, @"order", nil];
															   [sections setObject:section forKey:key];
														   }
														   else
															   [[section valueForKey:@"rows"] addObject:type];
														   
														   if ([operation isCancelled])
															   *needsMore = NO;
													   }];
				[itemValues addObjectsFromArray:[[sections allValues] sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"order" ascending:YES]]]];
			}
		}
		[pool release];
	}];
	
	[operation setCompletionBlockInCurrentThread:^(void) {
		if (![operation isCancelled]) {
			self.subGroups = subGroupValues;
			if (itemValues.count > 0)
				self.groupItems = itemValues;
			[self.itemsTable reloadData];
		}
	}];
	
	[[EUOperationQueue sharedQueue] addOperation:operation];
}


- (void) searchWithSearchString:(NSString*) aSearchString {
	NSString *searchString = [[aSearchString copy] autorelease];
	NSMutableArray *values = [NSMutableArray array];
	
	__block EUOperation *operation = [EUOperation operationWithIdentifier:@"MarketGroupsViewController+Filter" name:NSLocalizedString(@"Searching...", nil)];
	[operation addExecutionBlock:^(void) {
		if ([operation isCancelled])
			return;
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		if (searchString.length >= 2) {
			NSMutableDictionary* sections = [NSMutableDictionary dictionary];
			[[EVEDBDatabase sharedDatabase] execWithSQLRequest:[NSString stringWithFormat:@"SELECT a.*, c.metaGroupName, c.metaGroupID from invTypes AS a LEFT JOIN invMetaTypes AS b ON a.typeID=b.typeID LEFT JOIN invMetaGroups AS c ON b.metaGroupID=c.metaGroupID LEFT JOIN dgmTypeAttributes AS d ON d.typeID=a.typeID AND d.attributeID=633 WHERE typeName LIKE \"%%%@%%\" AND marketGroupID IS NOT NULL ORDER BY d.value, typeName;", searchString]
												   resultBlock:^(NSDictionary *record, BOOL *needsMore) {
													   EVEDBInvType* type = [EVEDBInvType invTypeWithDictionary:record];
													   NSString* key = [record valueForKey:@"metaGroupID"];
													   if (!key)
														   key = @"z";
													   NSMutableDictionary* section = [sections valueForKey:key];
													   if (!section) {
														   NSString* title = [record valueForKey:@"metaGroupName"];
														   if (!title)
															   title = @"";
														   
														   section = [NSMutableDictionary dictionaryWithObjectsAndKeys:
																	  title, @"title",
																	  [NSMutableArray arrayWithObject:type], @"rows",
																	  key, @"order", nil];
														   [sections setObject:section forKey:key];
													   }
													   else
														   [[section valueForKey:@"rows"] addObject:type];
													   
													   if ([operation isCancelled])
														   *needsMore = NO;
												   }];
			[values addObjectsFromArray:[[sections allValues] sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"order" ascending:YES]]]];
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
