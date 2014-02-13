//
//  NCDatabaseNPCViewController.m
//  Neocom
//
//  Created by Артем Шиманский on 27.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCDatabaseNPCViewController.h"
#import "NCDatabaseTypeInfoViewController.h"
#import "NCTableViewCell.h"

@interface NCDatabaseNPCViewController ()
@property (nonatomic, strong) NSArray* rows;
@property (nonatomic, strong) NSArray* searchResults;
@end

@implementation NCDatabaseNPCViewController

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
	
	NSMutableArray* rows = [NSMutableArray new];
	
	[[self taskManager] addTaskWithIndentifier:NCTaskManagerIdentifierNone
										 title:NCTaskManagerDefaultTitle
										 block:^(NCTask *task) {
											 if (self.npcGroup == nil) {
												 [[EVEDBDatabase sharedDatabase] execSQLRequest:@"SELECT * FROM npcGroup WHERE parentNpcGroupID IS NULL ORDER BY npcGroupName;"
																					resultBlock:^(sqlite3_stmt *stmt, BOOL *needsMore) {
																						[rows addObject:[[EVEDBNpcGroup alloc] initWithStatement:stmt]];
																						if ([task isCancelled])
																							*needsMore = NO;
																					}];
											 }
											 else if (self.npcGroup.groupID > 0) {
												 [[EVEDBDatabase sharedDatabase] execSQLRequest:[NSString stringWithFormat:@"SELECT * from invTypes WHERE groupID = %d ORDER BY typeName;", self.npcGroup.groupID]
																					resultBlock:^(sqlite3_stmt *stmt, BOOL *needsMore) {
																						[rows addObject:[[EVEDBInvType alloc] initWithStatement:stmt]];
																						if ([task isCancelled])
																							*needsMore = NO;
																					}];
											 }
											 else {
												 [[EVEDBDatabase sharedDatabase] execSQLRequest:[NSString stringWithFormat:@"SELECT * from npcGroup WHERE parentNpcGroupID = %d ORDER BY npcGroupName;", self.npcGroup.npcGroupID]
																					resultBlock:^(sqlite3_stmt *stmt, BOOL *needsMore) {
																						[rows addObject:[[EVEDBNpcGroup alloc] initWithStatement:stmt]];
																						if ([task isCancelled])
																							*needsMore = NO;
																					}];
											 }
										 }
							 completionHandler:^(NCTask *task) {
								 self.rows = rows;
								 [self.tableView reloadData];
							 }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	id row = [sender object];
	if ([segue.identifier isEqualToString:@"NCDatabaseNPCViewController"]) {
		NCDatabaseNPCViewController* destinationViewController = segue.destinationViewController;
		destinationViewController.npcGroup = row;
	}
	else if ([segue.identifier isEqualToString:@"NCDatabaseTypeInfoViewController"]) {
		NCDatabaseTypeInfoViewController* destinationViewController = segue.destinationViewController;
		destinationViewController.type = row;
	}
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return tableView == self.tableView ? [self.rows count] : [self.searchResults count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	id row = tableView == self.tableView ? self.rows[indexPath.row] : self.searchResults[indexPath.row];
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
		static NSString *CellIdentifier = @"NpcGroupCell";
		NCTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
		if (!cell)
			cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier];
		
		cell.textLabel.text = [row npcGroupName];
		
		NSString* iconImageName = [row iconName];
		if (iconImageName)
			cell.imageView.image = [UIImage imageNamed:iconImageName];
		else
			cell.imageView.image = [UIImage imageNamed:@"Icons/icon38_174.png"];
		cell.object = row;
		return cell;
	}
	return nil;
}

#pragma mark - NCTableViewController

- (NSString*) recordID {
	return nil;
}

- (void) searchWithSearchString:(NSString*) searchString {
	NSMutableArray* searchResults = [NSMutableArray new];
	[[self taskManager] addTaskWithIndentifier:NCTaskManagerIdentifierAuto
										 title:nil
										 block:^(NCTask *task) {
											 if ([task isCancelled])
												 return;
											 if (searchString.length >= 2) {
												 [[EVEDBDatabase sharedDatabase] execSQLRequest:[NSString stringWithFormat:@"SELECT a.* from invTypes AS a, invGroups AS b WHERE a.groupID=b.groupID AND b.categoryID=11 AND typeName LIKE \"%%%@%%\"ORDER BY typeName;", searchString]
																					resultBlock:^(sqlite3_stmt *stmt, BOOL *needsMore) {
																						EVEDBInvType* type = [[EVEDBInvType alloc] initWithStatement:stmt];
																						[searchResults addObject:type];
																						
																						if ([task isCancelled])
																							*needsMore = NO;
																					}];
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
