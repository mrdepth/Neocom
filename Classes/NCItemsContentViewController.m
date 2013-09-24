//
//  NCItemsContentViewController.m
//  EVEUniverse
//
//  Created by mr_depth on 04.08.13.
//
//

#import "NCItemsContentViewController.h"
#import "GroupedCell.h"
#import "EUOperationQueue.h"
#import "EVEDBAPI.h"
#import "NCItemsViewController.h"
#import "appearance.h"
#import "CollapsableTableHeaderView.h"
#import "UIView+Nib.h"
#import "UIViewController+Neocom.h"
#import "ItemViewController.h"

@interface EVEDBInvMarketGroup ()
@property (nonatomic, strong, readonly) NSMutableArray* subgroups;
@end

@interface NCItemsViewController()
@property (nonatomic, strong) NSArray* groups;
@property (nonatomic, strong) NSSet* conditionsTables;
@end

@interface NCItemsContentViewController ()
@property (nonatomic, strong) NSArray* groups;
@property (nonatomic, assign) NSInteger groupID;
@property (nonatomic, strong) NSArray* sections;
@property (nonatomic, strong) NSArray* searchResult;
@property (nonatomic, strong) NSString* typesRequest;
@property (nonatomic, strong) NSString* searchRequest;

- (void) reload;
- (void) searchWithSearchString:(NSString*) aSearchString;

@end



@implementation NCItemsContentViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	self.view.backgroundColor = [UIColor colorWithNumber:AppearanceBackgroundColor];
	if (!self.groups)
		[self reload];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	if (tableView == self.searchDisplayController.searchResultsTableView)
		return self.searchResult.count;
	else
		return self.groupID ? self.sections.count : 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	if (tableView == self.searchDisplayController.searchResultsTableView)
		return [self.searchResult[section][@"rows"] count];
	else
		return self.groupID ? [self.sections[section][@"rows"] count] : self.groups.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *cellIdentifier = @"Cell";
	
	GroupedCell* cell = (GroupedCell*) [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	if (cell == nil) {
		cell = [[GroupedCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];//[ItemCellView cellWithNibName:@"ItemCellView" bundle:nil reuseIdentifier:cellIdentifier];
	}
	
	if (tableView == self.searchDisplayController.searchResultsTableView) {
		EVEDBInvType* row = self.searchResult[indexPath.section][@"rows"][indexPath.row];
		cell.textLabel.text = row.typeName;
		cell.imageView.image = [UIImage imageNamed:row.typeSmallImageName];
		cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
	}
	else {
		if (self.groupID) {
			EVEDBInvType* row = self.sections[indexPath.section][@"rows"][indexPath.row];
			cell.textLabel.text = row.typeName;
			cell.imageView.image = [UIImage imageNamed:row.typeSmallImageName];
			cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
		}
		else {
			EVEDBInvMarketGroup* row = self.groups[indexPath.row];
			cell.textLabel.text = row.marketGroupName;
			if (row.icon.iconImageName)
				cell.imageView.image = [UIImage imageNamed:row.icon.iconImageName];
			else
				cell.imageView.image = [UIImage imageNamed:@"Icons/icon38_174.png"];
			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		}
	}
	
	GroupedCellGroupStyle groupStyle = 0;
	if (indexPath.row == 0)
		groupStyle |= GroupedCellGroupStyleTop;
	if (indexPath.row == [self tableView:tableView numberOfRowsInSection:indexPath.section] - 1)
		groupStyle |= GroupedCellGroupStyleBottom;
	cell.groupStyle = groupStyle;
	return cell;
}

- (NSString*) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	if (tableView == self.searchDisplayController.searchResultsTableView)
		return self.searchResult[section][@"title"];
	else
		return self.groupID ? self.sections[section][@"title"] : nil;
}

#pragma mark - Table view delegate

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
	NSString* title = [self tableView:tableView titleForHeaderInSection:section];
	if (title) {
		CollapsableTableHeaderView* view = [CollapsableTableHeaderView viewWithNibName:@"CollapsableTableHeaderView" bundle:nil];
		view.titleLabel.text = title;
		return view;
	}
	else
		return nil;
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
	return [self tableView:tableView titleForHeaderInSection:section] ? 20 : 0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (tableView == self.searchDisplayController.searchResultsTableView) {
		NCItemsViewController* itemsViewController = (NCItemsViewController*) self.navigationController;
		if (itemsViewController.completionHandler) {
			EVEDBInvType* type = self.searchResult[indexPath.section][@"rows"][indexPath.row];
			itemsViewController.completionHandler(type);
		}
//		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
//			[self dismissViewControllerAnimated:YES completion:nil];
	}
	else if (self.groupID) {
		NCItemsViewController* itemsViewController = (NCItemsViewController*) self.navigationController;
		if (itemsViewController.completionHandler) {
			EVEDBInvType* type = self.sections[indexPath.section][@"rows"][indexPath.row];
			itemsViewController.completionHandler(type);
		}
//		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
//			[self dismissViewControllerAnimated:YES completion:nil];
	}
	else {
		NCItemsContentViewController* controller = [[NCItemsContentViewController alloc] initWithNibName:@"NCItemsContentViewController" bundle:nil];
		
		EVEDBInvMarketGroup* marketGroup = self.groups[indexPath.row];
		while (marketGroup.subgroups.count == 1)
			marketGroup = marketGroup.subgroups[0];
		
		if (marketGroup.subgroups.count > 0)
			controller.groups = marketGroup.subgroups;
		else
			controller.groupID = marketGroup.marketGroupID;
		
		controller.title = marketGroup.marketGroupName;
		[self.navigationController pushViewController:controller animated:YES];
	}
}

- (void) tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
	EVEDBInvType* type = nil;
	
	if (tableView == self.searchDisplayController.searchResultsTableView) {
		type = self.searchResult[indexPath.section][@"rows"][indexPath.row];
	}
	else if (self.groupID) {
		type = self.sections[indexPath.section][@"rows"][indexPath.row];
	}
	else {
	}
	if (type) {
		ItemViewController *itemViewController = [[ItemViewController alloc] initWithNibName:@"ItemViewController" bundle:nil];
		itemViewController.type = type;
		[itemViewController setActivePage:ItemViewControllerActivePageInfo];
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
			UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:itemViewController];
			navController.modalPresentationStyle = UIModalPresentationFormSheet;
			[self presentViewController:navController animated:YES completion:nil];
		}
		else
			[self.navigationController pushViewController:itemViewController animated:YES];
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
	tableView.backgroundView = nil;
	tableView.backgroundColor = [UIColor colorWithNumber:AppearanceBackgroundColor];
}

#pragma mark - Private

- (void) reload {
	EUOperation* operation = [EUOperation operationWithIdentifier:@"NCItemsContentViewController+reload" name:@"Loading..."];
	__block NSArray* sections = nil;
	__block NSArray* groups = nil;
	
	[operation addExecutionBlock:^{
		NSMutableDictionary* sectionsDic = [NSMutableDictionary dictionary];
		if (!self.groups)
			groups = groups = self.itemsViewController.groups;
		if (groups.count == 1)
			self.groupID = [groups[0] marketGroupID];
		
		if (self.groupID) {
			EVEDBDatabase* database = [EVEDBDatabase sharedDatabase];
			[database execSQLRequest:self.typesRequest resultBlock:^(sqlite3_stmt *stmt, BOOL *needsMore) {
				EVEDBInvType* type = [[EVEDBInvType alloc] initWithStatement:stmt];
				EVEDBInvMetaGroup* metaGroup = [[EVEDBInvMetaGroup alloc] initWithStatement:stmt];
				
				NSNumber* key = @(metaGroup.metaGroupID);
				NSDictionary* section = sectionsDic[key];
				if (!section) {
					NSString* title = metaGroup.metaGroupName ? metaGroup.metaGroupName : @"";
					
					section = @{@"title": title, @"rows": [NSMutableArray arrayWithObject:type], @"order": key};
					sectionsDic[key] = section;
				}
				else
					[section[@"rows"] addObject:type];
			}];
			sections = [[sectionsDic allValues] sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"order" ascending:YES]]];;
		}
	}];
	
	[operation setCompletionBlockInMainThread:^{
		self.sections = sections;
		self.groups = groups;
		[self.tableView reloadData];
	}];
	
	[[EUOperationQueue sharedQueue] addOperation:operation];
}

- (NSString*) typesRequest {
	NCItemsViewController* itemsViewController = (NCItemsViewController*) self.navigationController;
	
	if (!_typesRequest) {
		NSMutableSet* fromTables = [[NSMutableSet alloc] initWithObjects: @"invTypes", nil];
		NSMutableArray* allConditions = [[NSMutableArray alloc] initWithObjects:[NSString stringWithFormat:@"invTypes.marketGroupID = %d", self.groupID], @"invTypes.published = 1", nil];
		
		[fromTables unionSet:itemsViewController.conditionsTables];
		[allConditions addObjectsFromArray:itemsViewController.conditions];
		
		_typesRequest = [NSString stringWithFormat:@"SELECT invTypes.*, invMetaGroups.* FROM invTypes \
						 LEFT JOIN invMetaTypes ON invTypes.typeID=invMetaTypes.typeID \
						 LEFT JOIN invMetaGroups ON invMetaTypes.metaGroupID=invMetaGroups.metaGroupID \
						 LEFT JOIN dgmTypeAttributes ON dgmTypeAttributes.typeID=invTypes.typeID AND dgmTypeAttributes.attributeID=633 \
						 WHERE invTypes.typeID IN \
						 (SELECT invTypes.typeID FROM %@ WHERE %@) GROUP BY invTypes.typeID ORDER BY dgmTypeAttributes.value, typeName;",
						 [[fromTables allObjects] componentsJoinedByString:@","], [allConditions componentsJoinedByString:@" AND "]];

	}
	return _typesRequest;
}

- (NSString*) searchRequest {
	NCItemsViewController* itemsViewController = (NCItemsViewController*) self.navigationController;
	
	if (!_searchRequest) {
		NSMutableSet* fromTables = [[NSMutableSet alloc] initWithObjects: @"invTypes", nil];
		NSMutableArray* allConditions = [[NSMutableArray alloc] initWithObjects:@"invTypes.typeName like \"%%%@%%\"", @"invTypes.published = 1", nil];
		
		[fromTables unionSet:itemsViewController.conditionsTables];
		[allConditions addObjectsFromArray:itemsViewController.conditions];
		
		_searchRequest = [NSString stringWithFormat:@"SELECT invTypes.*, invMetaGroups.* FROM invTypes \
						 LEFT JOIN invMetaTypes ON invTypes.typeID=invMetaTypes.typeID \
						 LEFT JOIN invMetaGroups ON invMetaTypes.metaGroupID=invMetaGroups.metaGroupID \
						 LEFT JOIN dgmTypeAttributes ON dgmTypeAttributes.typeID=invTypes.typeID AND dgmTypeAttributes.attributeID=633 \
						 WHERE invTypes.typeID IN \
						 (SELECT invTypes.typeID FROM %@ WHERE %@) GROUP BY invTypes.typeID ORDER BY dgmTypeAttributes.value, typeName;",
						 [[fromTables allObjects] componentsJoinedByString:@","], [allConditions componentsJoinedByString:@" AND "]];
		
	}
	return _searchRequest;
}

- (void) searchWithSearchString:(NSString*) searchString {
	if (searchString.length > 1) {
		NSString* searchRequest = [NSString stringWithFormat:self.searchRequest, searchString];
		
		EUOperation *operation = [EUOperation operationWithIdentifier:@"NCItemsContentViewController+searchWithSearchString" name:NSLocalizedString(@"Searching...", nil)];
		__weak EUOperation* weakOperation = operation;
		__block NSArray* sections = nil;
		
		[operation addExecutionBlock:^{
			NSMutableDictionary* sectionsDic = [NSMutableDictionary dictionary];
			EVEDBDatabase* database = [EVEDBDatabase sharedDatabase];
			[database execSQLRequest:searchRequest resultBlock:^(sqlite3_stmt *stmt, BOOL *needsMore) {
				EVEDBInvType* type = [[EVEDBInvType alloc] initWithStatement:stmt];
				EVEDBInvMetaGroup* metaGroup = [[EVEDBInvMetaGroup alloc] initWithStatement:stmt];
				
				NSNumber* key = @(metaGroup.metaGroupID);
				NSDictionary* section = sectionsDic[key];
				if (!section) {
					NSString* title = metaGroup.metaGroupName ? metaGroup.metaGroupName : @"";
					
					section = @{@"title": title, @"rows": [NSMutableArray arrayWithObject:type], @"order": key};
					sectionsDic[key] = section;
				}
				else
					[section[@"rows"] addObject:type];
				if ([weakOperation isCancelled])
					*needsMore = NO;
			}];
			
			if ([weakOperation isCancelled])
				return;
			
			sections = [[sectionsDic allValues] sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"order" ascending:YES]]];;
		}];
		
		[operation setCompletionBlockInMainThread:^{
			if (![weakOperation isCancelled]) {
				self.searchResult = sections;
				[self.searchDisplayController.searchResultsTableView reloadData];
			}
		}];
		
		[[EUOperationQueue sharedQueue] addOperation:operation];
	}
	else {
		self.searchResult = nil;
		[self.searchDisplayController.searchResultsTableView reloadData];
	}
}

@end
