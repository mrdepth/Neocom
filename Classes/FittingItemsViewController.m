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
@property (nonatomic, retain) NSMutableArray *subGroups;
@property (nonatomic, retain) NSMutableArray *groupItems;
@property (nonatomic, retain) NSMutableArray *filteredValues;

- (void) reload;
@end

@implementation FittingItemsViewController

//@synthesize group;
@synthesize modifiedItem;

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
	[self reload];
	// Do any additional setup after loading the view.
}

- (void) viewDidUnload {
	self.tableView = nil;
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

- (void) dealloc {
	[_tableView release];
	[_except release];
	[_subGroups release];
	[_groupItems release];
	[_filteredValues release];
	[_searchRequest release];
	[_groupsRequest release];
	[_typesRequest release];
	[super dealloc];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) setMarketGroupID:(NSInteger)value {
	if ([self.navigationController.viewControllers objectAtIndex:0] == self) {
		[self.navigationController popToRootViewControllerAnimated:YES];
		self.subGroups = nil;
		self.groupItems = nil;
		self.filteredValues = nil;
		if (value) {
			self.groupsRequest = nil;
			self.typesRequest = nil;
			self.searchRequest = nil;
		}
		if ([self.searchDisplayController isActive])
			[self.searchDisplayController setActive:NO];
		[self.tableView reloadData];
	}
	_marketGroupID = value;
}

- (NSString*) typesRequest {
	if (!_typesRequest && self.marketGroupID) {
		NSString* exceptString = [self.except componentsJoinedByString:@","];
		self.typesRequest = [NSString stringWithFormat:@"SELECT a.*, c.metaGroupName, c.metaGroupID from invTypes AS a LEFT JOIN invMetaTypes AS b ON a.typeID=b.typeID LEFT JOIN invMetaGroups AS c ON b.metaGroupID=c.metaGroupID LEFT JOIN dgmTypeAttributes AS d ON d.typeID=a.typeID AND d.attributeID=633 WHERE marketGroupID = %d %@ ORDER BY d.value, typeName;",
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
		[navController release];
	}
	else
		[self.navigationController pushViewController:controller animated:YES];
	[controller release];
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
		[controller release];
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
		tableView.backgroundView = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"background4.png"]] autorelease];
		tableView.backgroundView.contentMode = UIViewContentModeTopLeft;
	}
	else {
		tableView.backgroundView = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"background1.png"]] autorelease];
		tableView.backgroundView.contentMode = UIViewContentModeTop;
	}
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
	[operation addExecutionBlock:^(void) {
		@autoreleasepool {
			NSMutableArray* test = [NSMutableArray array];
			EVEDBDatabase* database = [EVEDBDatabase sharedDatabase];
			NSString* exceptString = [self.except componentsJoinedByString:@","];
			
			[database execWithSQLRequest:groupsRequest
							 resultBlock:^(NSDictionary *record, BOOL *needsMore) {
								 [test addObject:[record valueForKey:@"marketGroupID"]];

								 [subGroupValues addObject:[EVEDBInvMarketGroup invMarketGroupWithDictionary:record]];
								 if ([operation isCancelled])
									 *needsMore = NO;
							 }];

			while (test.count > 0) {
				NSString* testID = [test objectAtIndex:0];
				__block BOOL isLast = YES;

				[database execWithSQLRequest:[NSString stringWithFormat:@"SELECT marketGroupID FROM invMarketGroups WHERE parentGroupID=%@ %@;",
											  testID,
											  exceptString ? [NSString stringWithFormat:@" AND marketGroupID NOT IN (%@)", exceptString] : @""]
								 resultBlock:^(NSDictionary *record, BOOL *needsMore) {
									 isLast = NO;
									 [test addObject:[record valueForKey:@"marketGroupID"]];
								 }];
				if (isLast)
					[marketGroupsTmp addObject:testID];
				[test removeObjectAtIndex:0];
			}

			if (subGroupValues.count == 0) {
				if (self.marketGroupID)
					[marketGroupsTmp addObject:@(self.marketGroupID)];
				
				NSMutableDictionary* sections = [NSMutableDictionary dictionary];
				[database execWithSQLRequest:typesRequest
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

	}];
	
	[operation setCompletionBlockInCurrentThread:^(void) {
		if (![operation isCancelled]) {
			if (marketGroupsTmp.count > 0)
				self.searchRequest = [NSString stringWithFormat:@"SELECT a.*, c.metaGroupName, c.metaGroupID from invTypes AS a LEFT JOIN invMetaTypes AS b ON a.typeID=b.typeID LEFT JOIN invMetaGroups AS c ON b.metaGroupID=c.metaGroupID LEFT JOIN dgmTypeAttributes AS d ON d.typeID=a.typeID AND d.attributeID=633 WHERE typeName LIKE \"%%%%%%@%%%%\" AND marketGroupID IN (%@) ORDER BY d.value, typeName;", [marketGroupsTmp componentsJoinedByString:@","]];
			
			self.subGroups = subGroupValues;
			if (itemValues.count > 0)
				self.groupItems = itemValues;
			[self.tableView reloadData];
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
		if (searchString.length >= 2 && self.searchRequest) {
			NSMutableDictionary* sections = [NSMutableDictionary dictionary];
			[[EVEDBDatabase sharedDatabase] execWithSQLRequest:[NSString stringWithFormat:self.searchRequest, searchString]
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
