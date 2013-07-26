//
//  FittingItemsViewController.m
//  EVEUniverse
//
//  Created by Artem Shimanski on 21.01.13.
//
//

#import "FittingItemsViewController.h"
#import "EUOperationQueue.h"
#import "EVEDBAPI.h"
#import "ItemCellView.h"
#import "UITableViewCell+Nib.h"
#import "Globals.h"
#import "CollapsableTableHeaderView.h"
#import "UIView+Nib.h"
#import "ItemViewController.h"

@interface FittingItemsViewController ()
@property (nonatomic, strong) NSMutableArray *subGroups;
@property (nonatomic, strong) NSMutableArray *groupItems;
@property (nonatomic, strong) NSMutableArray *filteredValues;

- (void) reload;
@end

@implementation FittingItemsViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		self.tableView.backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"backgroundPopover~ipad.png"]];
		self.tableView.backgroundView.contentMode = UIViewContentModeTop;
	}
	else
		self.tableView.backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"background.png"]];
	[self reload];
	// Do any additional setup after loading the view.
}

- (void) viewDidUnload {
	self.subGroups = nil;
	self.groupItems = nil;
	self.filteredValues = nil;
	self.searchRequest = nil;
}

- (void) viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	if (!self.subGroups || !self.groupItems) {
		[self reload];
	}
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) setMarketGroupID:(NSInteger)value {
	if (value == _marketGroupID && value)
		return;
	
	if ([self.navigationController.viewControllers objectAtIndex:0] == self) {
		[self.navigationController popToRootViewControllerAnimated:YES];
		self.subGroups = nil;
		self.groupItems = nil;
		self.filteredValues = nil;
//		if (value) {
			self.groupsRequest = nil;
			self.typesRequest = nil;
			self.searchRequest = nil;
//		}
		if ([self.searchDisplayController isActive])
			[self.searchDisplayController setActive:NO];
		[self.tableView reloadData];
	}
	_marketGroupID = value;
}

- (NSString*) typesRequest {
	if (!_typesRequest && self.marketGroupID) {
		NSString* exceptString = [self.except componentsJoinedByString:@","];
		self.typesRequest = [NSString stringWithFormat:@"SELECT a.*, c.* from invTypes AS a LEFT JOIN invMetaTypes AS b ON a.typeID=b.typeID LEFT JOIN invMetaGroups AS c ON b.metaGroupID=c.metaGroupID LEFT JOIN dgmTypeAttributes AS d ON d.typeID=a.typeID AND d.attributeID=633 WHERE marketGroupID = %d %@ ORDER BY d.value, typeName;",
							 self.marketGroupID,
							 exceptString ? [NSString stringWithFormat:@" AND marketGroupID NOT IN (%@)", exceptString] : @""];
	}
	return _typesRequest;
}

- (NSString*) groupsRequest {
	if (!_groupsRequest && self.marketGroupID) {
		NSString* exceptString = [self.except componentsJoinedByString:@","];
		self.groupsRequest = [NSString stringWithFormat:@"SELECT * FROM invMarketGroups WHERE parentGroupID=%d %@ ORDER BY marketGroupName;",
							  self.marketGroupID,
							  exceptString ? [NSString stringWithFormat:@" AND marketGroupID NOT IN (%@)", exceptString] : @""];
	}
	return _groupsRequest;
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
		cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
	}
	else {
		if (self.groupItems) {
			EVEDBInvType *row = [[[self.groupItems objectAtIndex:indexPath.section] valueForKey:@"rows"] objectAtIndex:indexPath.row];
			cell.titleLabel.text = row.typeName;
			cell.iconImageView.image = [UIImage imageNamed:[row typeSmallImageName]];
			cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
		}
		else {
			EVEDBInvMarketGroup *row = [self.subGroups objectAtIndex:indexPath.row];
			cell.titleLabel.text = row.marketGroupName;
			if (row.icon.iconImageName)
				cell.iconImageView.image = [UIImage imageNamed:row.icon.iconImageName];
			else
				cell.iconImageView.image = [UIImage imageNamed:@"Icons/icon38_174.png"];
			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
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

- (void)tableView:(UITableView *)aTableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
	EVEDBInvType *row;
	if (self.searchDisplayController.searchResultsTableView == aTableView)
		row = [[[self.filteredValues objectAtIndex:indexPath.section] valueForKey:@"rows"] objectAtIndex:indexPath.row];
	else
		row = [[[self.groupItems objectAtIndex:indexPath.section] valueForKey:@"rows"] objectAtIndex:indexPath.row];
	
	ItemViewController *controller = [[ItemViewController alloc] initWithNibName:@"ItemViewController" bundle:nil];
	
	controller.type = row;
	[controller setActivePage:ItemViewControllerActivePageInfo];
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:controller];
		navController.modalPresentationStyle = UIModalPresentationFormSheet;
		[self.mainViewController presentModalViewController:navController animated:YES];
	}
	else
		[self.navigationController pushViewController:controller animated:YES];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	if (self.searchDisplayController.searchResultsTableView == tableView) {
		EVEDBInvType *row = [[[self.filteredValues objectAtIndex:indexPath.section] valueForKey:@"rows"] objectAtIndex:indexPath.row];
		[self.delegate fittingItemsViewController:self didSelectType:row];
	}
	else if (!self.groupItems) {
		EVEDBInvMarketGroup *row = [self.subGroups objectAtIndex:indexPath.row];
		FittingItemsViewController *controller = [[FittingItemsViewController alloc] initWithNibName:@"FittingItemsViewController" bundle:nil];
		controller.title = row.marketGroupName;
		controller.marketGroupID = row.marketGroupID;
		controller.delegate = self;
		controller.mainViewController = self.mainViewController;
		[self.navigationController pushViewController:controller animated:YES];
	}
	else {
		EVEDBInvType *row = [[[self.groupItems objectAtIndex:indexPath.section] valueForKey:@"rows"] objectAtIndex:indexPath.row];
		[self.delegate fittingItemsViewController:self didSelectType:row];
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

#pragma mark FittingItemsViewControllerDelegate

- (void) fittingItemsViewController:(FittingItemsViewController*) controller didSelectType:(EVEDBInvType*) type {
	[self.delegate fittingItemsViewController:self didSelectType:type];
}

#pragma mark - Private

- (void) reload {
	NSMutableArray* marketGroupsTmp = [NSMutableArray array];

	NSMutableArray *subGroupValues = [NSMutableArray array];
	NSMutableArray *itemValues = [NSMutableArray array];
	
	NSString* groupsRequest = self.groupsRequest;
	NSString* typesRequest = self.typesRequest;

	__block EUOperation *operation = [EUOperation operationWithIdentifier:@"FittingItemsViewController+Load" name:NSLocalizedString(@"Loading...", nil)];
	__weak EUOperation* weakOperation = operation;
	[operation addExecutionBlock:^(void) {
		@autoreleasepool {
			NSMutableArray* test = [NSMutableArray array];
			EVEDBDatabase* database = [EVEDBDatabase sharedDatabase];
			NSString* exceptString = [self.except componentsJoinedByString:@","];
			
			[database execSQLRequest:groupsRequest
							 resultBlock:^(sqlite3_stmt *stmt, BOOL *needsMore) {
								 EVEDBInvMarketGroup* marketGroup = [[EVEDBInvMarketGroup alloc] initWithStatement:stmt];
								 [test addObject:@(marketGroup.marketGroupID)];

								 [subGroupValues addObject:marketGroup];
								 if ([weakOperation isCancelled])
									 *needsMore = NO;
							 }];

			while (test.count > 0) {
				NSNumber* testID = [test objectAtIndex:0];
				__block BOOL isLast = YES;

				[database execSQLRequest:[NSString stringWithFormat:@"SELECT marketGroupID FROM invMarketGroups WHERE parentGroupID=%@ %@;",
											  testID,
											  exceptString ? [NSString stringWithFormat:@" AND marketGroupID NOT IN (%@)", exceptString] : @""]
								 resultBlock:^(sqlite3_stmt *stmt, BOOL *needsMore) {
									 NSInteger marketGroupID = sqlite3_column_int(stmt, 0);
									 isLast = NO;
									 [test addObject:@(marketGroupID)];
								 }];
				if (isLast)
					[marketGroupsTmp addObject:testID];
				[test removeObjectAtIndex:0];
			}

			if (subGroupValues.count == 0) {
				if (self.marketGroupID)
					[marketGroupsTmp addObject:@(self.marketGroupID)];
				
				NSMutableDictionary* sections = [NSMutableDictionary dictionary];
				[database execSQLRequest:typesRequest
								 resultBlock:^(sqlite3_stmt *stmt, BOOL *needsMore) {
									 EVEDBInvType* type = [[EVEDBInvType alloc] initWithStatement:stmt];
									 EVEDBInvMetaGroup* metaGroup = [[EVEDBInvMetaGroup alloc] initWithStatement:stmt];
									 
									 NSNumber* key = @(metaGroup.metaGroupID);
									 NSMutableDictionary* section = [sections objectForKey:key];
									 if (!section) {
										 NSString* title = metaGroup.metaGroupName ? metaGroup.metaGroupName : @"";
										 
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
	
	[operation setCompletionBlockInMainThread:^(void) {
		if (![weakOperation isCancelled]) {
			if (marketGroupsTmp.count > 0)
				self.searchRequest = [NSString stringWithFormat:@"SELECT a.*, c.* from invTypes AS a LEFT JOIN invMetaTypes AS b ON a.typeID=b.typeID LEFT JOIN invMetaGroups AS c ON b.metaGroupID=c.metaGroupID LEFT JOIN dgmTypeAttributes AS d ON d.typeID=a.typeID AND d.attributeID=633 WHERE typeName LIKE \"%%%%%%@%%%%\" AND marketGroupID IN (%@) ORDER BY d.value, typeName;", [marketGroupsTmp componentsJoinedByString:@","]];
			
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
		if (searchString.length >= 2 && self.searchRequest) {
			NSMutableDictionary* sections = [NSMutableDictionary dictionary];
			[[EVEDBDatabase sharedDatabase] execSQLRequest:[NSString stringWithFormat:self.searchRequest, searchString]
												   resultBlock:^(sqlite3_stmt *stmt, BOOL *needsMore) {
													   EVEDBInvType* type = [[EVEDBInvType alloc] initWithStatement:stmt];
													   EVEDBInvMetaGroup* metaGroup = [[EVEDBInvMetaGroup alloc] initWithStatement:stmt];
													   
													   NSNumber* key = @(metaGroup.metaGroupID);
													   NSMutableDictionary* section = [sections objectForKey:key];
													   if (!section) {
														   NSString* title = metaGroup.metaGroupName ? metaGroup.metaGroupName : @"";
														   
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
	
	[operation setCompletionBlockInMainThread:^(void) {
		if (![weakOperation isCancelled]) {
			self.filteredValues = values;
			[self.searchDisplayController.searchResultsTableView reloadData];
		}
	}];
	
	[[EUOperationQueue sharedQueue] addOperation:operation];
}

@end
