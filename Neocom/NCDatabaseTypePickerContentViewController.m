//
//  NCDatabaseTypePickerContentViewController.m
//  Neocom
//
//  Created by Shimanski Artem on 28.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCDatabaseTypePickerContentViewController.h"
#import "NCDatabaseTypePickerViewController.h"
#import "NCTableViewCell.h"
#import "NCDatabaseTypeInfoViewController.h"

@interface EVEDBInvMarketGroup ()
@property (nonatomic, strong, readonly) NSMutableArray* subgroups;
@end

@interface NCDatabaseTypePickerViewController ()
@property (nonatomic, strong) NSArray* conditions;
@property (nonatomic, copy) void (^completionHandler)(EVEDBInvType* type);
@property (nonatomic, strong) NSArray* groups;
@property (nonatomic, strong) NSSet* conditionsTables;

@end

@interface NCDatabaseTypePickerContentViewController ()
@property (nonatomic, strong) NSArray* sections;
@property (nonatomic, strong) NSArray* searchResult;
@property (nonatomic, strong) NSString* typesRequest;
@property (nonatomic, strong) NSString* searchRequest;

@end

@implementation NCDatabaseTypePickerContentViewController

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
	self.refreshControl = nil;
	// Do any additional setup after loading the view.
}

- (void) viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	if (!self.groups)
		[self reload];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	if ([segue.identifier isEqualToString:@"NCDatabaseTypePickerContentViewController"]) {
		NCDatabaseTypePickerContentViewController* destinationViewController = segue.destinationViewController;
		EVEDBInvMarketGroup* marketGroup = [sender object];
		while (marketGroup.subgroups.count == 1)
			marketGroup = marketGroup.subgroups[0];
		
		if (marketGroup.subgroups.count > 0)
			destinationViewController.groups = marketGroup.subgroups;
		else
			destinationViewController.groupID = marketGroup.marketGroupID;
		
		destinationViewController.title = marketGroup.marketGroupName;
	}
	else if ([segue.identifier isEqualToString:@"NCDatabaseTypeInfoViewController"]) {
		NCDatabaseTypeInfoViewController* destinationViewController = segue.destinationViewController;
		destinationViewController.type = [sender object];
	}
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	if (tableView == self.searchDisplayController.searchResultsTableView)
		return self.searchResult.count;
	else
		return self.groupID ? self.sections.count : 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	if (tableView == self.searchDisplayController.searchResultsTableView)
		return [self.searchResult[section][@"rows"] count];
	else
		return self.groupID ? [self.sections[section][@"rows"] count] : self.groups.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	id row;
	if (tableView == self.searchDisplayController.searchResultsTableView)
		row = self.searchResult[indexPath.section][@"rows"][indexPath.row];
	else if (self.groupID)
		row = self.sections[indexPath.section][@"rows"][indexPath.row];
	else
		row = self.groups[indexPath.row];
	
	if ([row isKindOfClass:[EVEDBInvType class]]) {
		static NSString *CellIdentifier = @"TypeCell";
		NCTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
		if (!cell)
			cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier];
		cell.textLabel.text = [row typeName];
		cell.imageView.image = [UIImage imageNamed:[row typeSmallImageName]];
		cell.object = row;
		return cell;
	}
	else {
		static NSString *CellIdentifier = @"MarketGroupCell";
		NCTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
		if (!cell)
			cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier];
		
		if ([row isKindOfClass:[EVEDBInvCategory class]])
			cell.textLabel.text = [row categoryName];
		else
			cell.textLabel.text = [row marketGroupName];
		
		NSString* iconImageName = [row icon].iconImageName;
		if (iconImageName)
			cell.imageView.image = [UIImage imageNamed:iconImageName];
		else
			cell.imageView.image = [UIImage imageNamed:@"Icons/icon38_174.png"];
		cell.object = row;
		return cell;
	}
}

- (NSString*) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	if (tableView == self.searchDisplayController.searchResultsTableView)
		return self.searchResult[section][@"title"];
	else
		return self.groupID ? self.sections[section][@"title"] : nil;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	id row;
	if (tableView == self.searchDisplayController.searchResultsTableView)
		row = self.searchResult[indexPath.section][@"rows"][indexPath.row];
	else if (self.groupID)
		row = self.sections[indexPath.section][@"rows"][indexPath.row];
	else
		row = self.groups[indexPath.row];

	if ([row isKindOfClass:[EVEDBInvType class]]) {
		NCDatabaseTypePickerViewController* navigationController = (NCDatabaseTypePickerViewController*) self.navigationController;
		navigationController.completionHandler(row);
	}
}

#pragma mark - NCTableViewController

- (NSString*) recordID {
	return nil;
}

#pragma mark - Private

- (void) reload {
	__block NSArray* sections = nil;
	__block NSArray* groups = nil;
	
	[[self taskManager] addTaskWithIndentifier:NCTaskManagerIdentifierAuto
										 title:NCTaskManagerDefaultTitle
										 block:^(NCTask *task) {
											 NSMutableDictionary* sectionsDic = [NSMutableDictionary dictionary];
											 if (!self.groups)
												 groups = groups = [(NCDatabaseTypePickerViewController*) self.navigationController groups];
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
										 }
							 completionHandler:^(NCTask *task) {
								 self.sections = sections;
								 self.groups = groups;
								 [self.tableView reloadData];
							 }];
}

- (NSString*) typesRequest {
	NCDatabaseTypePickerViewController* navigationController = (NCDatabaseTypePickerViewController*) self.navigationController;
	
	if (!_typesRequest) {
		NSMutableSet* fromTables = [[NSMutableSet alloc] initWithObjects: @"invTypes", nil];
		NSMutableArray* allConditions = [[NSMutableArray alloc] initWithObjects:[NSString stringWithFormat:@"invTypes.marketGroupID = %d", self.groupID], @"invTypes.published = 1", nil];
		
		[fromTables unionSet:navigationController.conditionsTables];
		[allConditions addObjectsFromArray:navigationController.conditions];
		
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
	NCDatabaseTypePickerViewController* navigationController = (NCDatabaseTypePickerViewController*) self.navigationController;
	
	if (!_searchRequest) {
		NSMutableSet* fromTables = [[NSMutableSet alloc] initWithObjects: @"invTypes", nil];
		NSMutableArray* allConditions = [[NSMutableArray alloc] initWithObjects:@"invTypes.typeName like \"%%%@%%\"", @"invTypes.published = 1", nil];
		
		[fromTables unionSet:navigationController.conditionsTables];
		[allConditions addObjectsFromArray:navigationController.conditions];
		
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
		__block NSArray* searchResults = nil;

		[[self taskManager] addTaskWithIndentifier:NCTaskManagerIdentifierAuto
											 title:NCTaskManagerDefaultTitle
											 block:^(NCTask *task) {
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
													 if ([task isCancelled])
														 *needsMore = NO;
												 }];
												 
												 if ([task isCancelled])
													 return;
												 
												 searchResults = [[sectionsDic allValues] sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"order" ascending:YES]]];;
											 }
								 completionHandler:^(NCTask *task) {
									 if (![task isCancelled]) {
										 self.searchResult = searchResults;
										 [self.searchDisplayController.searchResultsTableView reloadData];
									 }
								 }];
	}
	else {
		self.searchResult = nil;
		[self.searchDisplayController.searchResultsTableView reloadData];
	}
}

@end
