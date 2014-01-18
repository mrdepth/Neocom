//
//  NCDatabaseMarketViewController.m
//  Neocom
//
//  Created by Shimanski Artem on 18.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCDatabaseMarketViewController.h"
#import "NCDatabaseTypeInfoViewController.h"
#import "NCTableViewCell.h"

@interface NCDatabaseMarketViewController ()
@property (nonatomic, strong) NSArray* sections;
@property (nonatomic, strong) NSArray* searchResults;
@end

@implementation NCDatabaseMarketViewController

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
	
	if (1) {
		__block NSArray* sections = nil;
		
		[[self taskManager] addTaskWithIndentifier:NCTaskManagerIdentifierNone
											 title:NCTaskManagerDefaultTitle
											 block:^(NCTask *task) {
												 NSMutableArray* marketGroups = [NSMutableArray new];

												 if (self.marketGroup == nil) {
													 [[EVEDBDatabase sharedDatabase] execSQLRequest:@"SELECT * FROM invMarketGroups WHERE parentGroupID IS NULL ORDER BY marketGroupName;"
																						resultBlock:^(sqlite3_stmt *stmt, BOOL *needsMore) {
																							[marketGroups addObject:[[EVEDBInvMarketGroup alloc] initWithStatement:stmt]];
																							if ([task isCancelled])
																								*needsMore = NO;
																						}];
													 sections = @[@{@"rows" : marketGroups}];
												 }
												 else {
													 [[EVEDBDatabase sharedDatabase] execSQLRequest:[NSString stringWithFormat:@"SELECT * FROM invMarketGroups WHERE parentGroupID=%d ORDER BY marketGroupName;", self.marketGroup.marketGroupID]
																						resultBlock:^(sqlite3_stmt *stmt, BOOL *needsMore) {
																							[marketGroups addObject:[[EVEDBInvMarketGroup alloc] initWithStatement:stmt]];
																							if ([task isCancelled])
																								*needsMore = NO;
																						}];
													 if (marketGroups.count == 0) {
														 NSMutableDictionary* dic = [NSMutableDictionary dictionary];
														 [[EVEDBDatabase sharedDatabase] execSQLRequest:[NSString stringWithFormat:@"SELECT c.metaGroupID, c.metaGroupName, a.* from invTypes AS a LEFT JOIN invMetaTypes AS b ON a.typeID=b.typeID LEFT JOIN invMetaGroups AS c ON b.metaGroupID=c.metaGroupID LEFT JOIN dgmTypeAttributes AS d ON d.typeID=a.typeID AND d.attributeID=633 WHERE marketGroupID = %d ORDER BY d.value, typeName;", self.marketGroup.marketGroupID]
																							resultBlock:^(sqlite3_stmt *stmt, BOOL *needsMore) {
																								EVEDBInvType* type = [[EVEDBInvType alloc] initWithStatement:stmt];
																								int metaGroupID = sqlite3_column_int(stmt, 0);
																								NSNumber* key = @(metaGroupID);
																								NSMutableDictionary* section = dic[key];
																								if (!section) {
																									const char* metaGroupName = (const char*) sqlite3_column_text(stmt, 1);
																									NSString* title = metaGroupName ? [NSString stringWithCString:metaGroupName encoding:NSUTF8StringEncoding] : @"";
																									
																									section = [NSMutableDictionary dictionaryWithObjectsAndKeys:
																											   title, @"title",
																											   [NSMutableArray arrayWithObject:type], @"rows",
																											   key, @"order", nil];
																									dic[key] = section;
																								}
																								else
																									[section[@"rows"] addObject:type];
																								
																								if ([task isCancelled])
																									*needsMore = NO;
																							}];
														 sections = [[dic allValues] sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"order" ascending:YES]]];
													 }
													 else
														 sections = @[@{@"rows" : marketGroups}];
												 }
											 }
								 completionHandler:^(NCTask *task) {
									 self.sections = sections;
									 [self.tableView reloadData];
								 }];
	}
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	id row = [sender object];
	if ([segue.identifier isEqualToString:@"NCDatabaseMarketViewController"]) {
		NCDatabaseMarketViewController* destinationViewController = segue.destinationViewController;
		destinationViewController.marketGroup = row;
	}
	else {
		NCDatabaseTypeInfoViewController* destinationViewController = segue.destinationViewController;
		destinationViewController.type = row;
	}
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return tableView == self.tableView ? self.sections.count : self.searchResults.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return tableView == self.tableView ? [self.sections[section][@"rows"] count] : [self.searchResults[section][@"rows"] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	id row = tableView == self.tableView ? self.sections[indexPath.section][@"rows"][indexPath.row] : self.searchResults[indexPath.section][@"rows"][indexPath.row];
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
	return nil;
}

- (NSString*) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	return tableView == self.tableView ? self.sections[section][@"title"] : self.searchResults[section][@"title"];
}
/*
 #pragma mark - Navigation
 
 // In a story board-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
 {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 
 */

#pragma mark - NCTableViewController

- (NSString*) recordID {
	return nil;
}

- (void) searchWithSearchString:(NSString*) searchString {
	__block NSArray* searchResults = nil;
	[[self taskManager] addTaskWithIndentifier:NCTaskManagerIdentifierAuto
										 title:nil
										 block:^(NCTask *task) {
											 if ([task isCancelled])
												 return;
											 if (searchString.length >= 2) {
												 NSMutableDictionary* sections = [NSMutableDictionary dictionary];
												 [[EVEDBDatabase sharedDatabase] execSQLRequest:[NSString stringWithFormat:@"SELECT c.metaGroupID, c.metaGroupName, a.* from invTypes AS a LEFT JOIN invMetaTypes AS b ON a.typeID=b.typeID LEFT JOIN invMetaGroups AS c ON b.metaGroupID=c.metaGroupID LEFT JOIN dgmTypeAttributes AS d ON d.typeID=a.typeID AND d.attributeID=633 WHERE typeName LIKE \"%%%@%%\" AND marketGroupID > 0 ORDER BY d.value, typeName;", searchString]
																					resultBlock:^(sqlite3_stmt *stmt, BOOL *needsMore) {
																						EVEDBInvType* type = [[EVEDBInvType alloc] initWithStatement:stmt];
																						int metaGroupID = sqlite3_column_int(stmt, 0);
																						NSNumber* key = metaGroupID > 0 ? @(metaGroupID) : @(INT_MAX);
																						NSMutableDictionary* section = [sections objectForKey:key];
																						if (!section) {
																							const char* metaGroupName = (const char*) sqlite3_column_text(stmt, 1);
																							NSString* title = metaGroupName ? [NSString stringWithCString:metaGroupName encoding:NSUTF8StringEncoding] : @"";
																							
																							section = [NSMutableDictionary dictionaryWithObjectsAndKeys:
																									   title, @"title",
																									   [NSMutableArray arrayWithObject:type], @"rows",
																									   key, @"order", nil];
																							sections[key] = section;
																						}
																						else
																							[section[@"rows"] addObject:type];
																						
																						if ([task isCancelled])
																							*needsMore = NO;
																					}];
												 searchResults = [[sections allValues] sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"order" ascending:YES]]];
											 }
										 }
							 completionHandler:^(NCTask *task) {
								 if (![task isCancelled]) {
									 self.searchResults = searchResults;
									 [self.searchDisplayController.searchResultsTableView reloadData];
								 }
							 }];
}


@end
