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
	self.subGroups = [NSMutableArray array];
	self.groupItems = [NSMutableArray array];
	self.filteredValues = [NSMutableArray array];
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
		return 1;
	else
		return 2;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
	if (section == 0) {
		if (self.searchDisplayController.searchResultsTableView == tableView)
			return filteredValues.count;
		else
			return subGroups.count;
	}
	else
		return groupItems.count;
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
		if (indexPath.section == 0) {
			EVEDBInvMarketGroup *row = [subGroups objectAtIndex:indexPath.row];
			cell.titleLabel.text = row.marketGroupName;
			if (row.icon.iconImageName)
				cell.iconImageView.image = [UIImage imageNamed:row.icon.iconImageName];
			else
				cell.iconImageView.image = [UIImage imageNamed:@"Icons/icon38_174.png"];
		}
		else {
			EVEDBInvType *row = [groupItems objectAtIndex:indexPath.row];
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
	else if (indexPath.section == 0) {
		MarketGroupsViewController *controller = [[MarketGroupsViewController alloc] initWithNibName:@"MarketGroupsViewController" bundle:nil];
		controller.parentGroup = [subGroups objectAtIndex:indexPath.row];
		[self.navigationController pushViewController:controller animated:YES];
		[controller release];
	}
	else {
		ItemViewController *controller = [[ItemViewController alloc] initWithNibName:@"ItemViewController" bundle:nil];
		controller.type = [groupItems objectAtIndex:indexPath.row];
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
			[[EVEDBDatabase sharedDatabase] execWithSQLRequest:[NSString stringWithFormat:@"SELECT * FROM invTypes WHERE marketGroupID=%d ORDER BY typeName", parentGroup.marketGroupID]
												   resultBlock:^(NSDictionary *record, BOOL *needsMore) {
													   [itemValues addObject:[EVEDBInvType invTypeWithDictionary:record]];
													   if ([operation isCancelled])
														   *needsMore = NO;
												   }];
		}
		[pool release];
	}];
	
	[operation setCompletionBlockInCurrentThread:^(void) {
		if (![operation isCancelled]) {
			self.subGroups = subGroupValues;
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
			[[EVEDBDatabase sharedDatabase] execWithSQLRequest:[NSString stringWithFormat:@"SELECT * FROM invTypes WHERE typeName LIKE \"%%%@%%\" AND marketGroupID IS NOT NULL ORDER BY typeName;", searchString]
												   resultBlock:^(NSDictionary *record, BOOL *needsMore) {
													   [values addObject:[EVEDBInvType invTypeWithDictionary:record]];
													   if ([operation isCancelled])
														   *needsMore = NO;
												   }];
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
