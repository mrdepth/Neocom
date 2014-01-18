//
//  NCDatabaseViewController.m
//  Neocom
//
//  Created by Артем Шиманский on 14.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCDatabaseViewController.h"
#import "NCDatabaseTypeInfoViewController.h"
#import "NCTableViewCell.h"

@interface NCDatabaseViewController ()
@property (nonatomic, strong) NSArray* rows;
@property (nonatomic, strong) NSArray* searchResults;
@end

@implementation NCDatabaseViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
	self.refreshControl = nil;
	
	if (!self.rows) {
		NSMutableArray* rows = [NSMutableArray new];
		
		[[self taskManager] addTaskWithIndentifier:NCTaskManagerIdentifierNone
											 title:NCTaskManagerDefaultTitle
											 block:^(NCTask *task) {
												 if (self.group) {
													 [[EVEDBDatabase sharedDatabase] execSQLRequest:[NSString stringWithFormat:@"SELECT * FROM invTypes WHERE groupID=%d%@ ORDER BY typeName;", self.group.groupID,
																									 self.filter == NCDatabaseFilterPublished ? @"WHERE published=1":
																									 self.filter == NCDatabaseFilterUnpublished ? @"WHERE published=0" : @""]
																						resultBlock:^(sqlite3_stmt *stmt, BOOL *needsMore) {
																							[rows addObject:[[EVEDBInvType alloc] initWithStatement:stmt]];
																							if ([task isCancelled])
																								*needsMore = NO;
																						}];
												 }
												 else if (self.category) {
													 [[EVEDBDatabase sharedDatabase] execSQLRequest:[NSString stringWithFormat:@"SELECT * FROM invGroups WHERE categoryID=%d%@ ORDER BY groupName;", self.category.categoryID,
																									 self.filter == NCDatabaseFilterPublished ? @"WHERE published=1":
																									 self.filter == NCDatabaseFilterUnpublished ? @"WHERE published=0" : @""]
																						resultBlock:^(sqlite3_stmt *stmt, BOOL *needsMore) {
																							[rows addObject:[[EVEDBInvGroup alloc] initWithStatement:stmt]];
																							if ([task isCancelled])
																								*needsMore = NO;
																						}];
												 }
												 else {
													 [[EVEDBDatabase sharedDatabase] execSQLRequest:[NSString stringWithFormat:@"SELECT * FROM invCategories %@ ORDER BY categoryName",
																									 self.filter == NCDatabaseFilterPublished ? @"WHERE published=1":
																									 self.filter == NCDatabaseFilterUnpublished ? @"WHERE published=0" : @""]
																						resultBlock:^(sqlite3_stmt *stmt, BOOL *needsMore) {
																							[rows addObject:[[EVEDBInvCategory alloc] initWithStatement:stmt]];
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
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	if ([segue.identifier isEqualToString:@"NCDatabaseViewController"]) {
		id row = [sender object];
		
		NCDatabaseViewController* destinationViewController = segue.destinationViewController;
		if ([row isKindOfClass:[EVEDBInvCategory class]])
			destinationViewController.category = row;
		else if ([row isKindOfClass:[EVEDBInvGroup class]])
			destinationViewController.group = row;
	}
	else {
		NCDatabaseTypeInfoViewController* destinationViewController = segue.destinationViewController;
		id row = [sender object];
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
    return tableView == self.tableView ? self.rows.count : self.searchResults.count;
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
		static NSString *CellIdentifier = @"CategoryGroupCell";
		NCTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
		if (!cell)
			cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier];
		
		if ([row isKindOfClass:[EVEDBInvCategory class]])
			cell.textLabel.text = [row categoryName];
		else
			cell.textLabel.text = [row groupName];
		
		NSString* iconImageName = [row icon].iconImageName;
		if (iconImageName)
			cell.imageView.image = [UIImage imageNamed:iconImageName];
		else
			cell.imageView.image = [UIImage imageNamed:@"Icons/icon38_174.png"];
		cell.object = row;
		return cell;
	}
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

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
	NSMutableArray* searchResults = [NSMutableArray new];
	[[self taskManager] addTaskWithIndentifier:NCTaskManagerIdentifierAuto
										 title:nil
										 block:^(NCTask *task) {
											 if ([task isCancelled])
												 return;
											 if (searchString.length >= 2) {
												 void (^block)(sqlite3_stmt* stmt, BOOL *needsMore) = ^(sqlite3_stmt* stmt, BOOL *needsMore) {
													 [searchResults addObject:[[EVEDBInvType alloc] initWithStatement:stmt]];
													 if ([task isCancelled])
														 *needsMore = NO;
												 };
												 
												 if (self.group != nil)
													 [[EVEDBDatabase sharedDatabase] execSQLRequest:[NSString stringWithFormat:@"SELECT * FROM invTypes WHERE groupID=%d AND typeName LIKE \"%%%@%%\"%@ ORDER BY typeName;",
																									 self.group.groupID,
																									 searchString,
																									 self.filter == NCDatabaseFilterPublished ? @" AND published=1" :
																									 self.filter == NCDatabaseFilterUnpublished ? @" AND published=0" : @""]
																						resultBlock:block];
												 else if (self.category != nil)
													 [[EVEDBDatabase sharedDatabase] execSQLRequest:[NSString stringWithFormat:@"SELECT invTypes.* FROM invTypes, invGroups WHERE invGroups.categoryID=%d AND invTypes.groupID=invGroups.groupID AND typeName LIKE \"%%%@%%\"%@ ORDER BY typeName;",
																									 self.category.categoryID,
																									 searchString,
																									 self.filter == NCDatabaseFilterPublished ? @" AND invTypes.published=1" :
																									 self.filter == NCDatabaseFilterUnpublished ? @" AND invTypes.published=0" : @""]
																						resultBlock:block];
												 else
													 [[EVEDBDatabase sharedDatabase] execSQLRequest:[NSString stringWithFormat:@"SELECT * FROM invTypes WHERE typeName LIKE \"%%%@%%\"%@ ORDER BY typeName;",
																									 searchString,
																									 self.filter == NCDatabaseFilterPublished ? @" AND published=1" :
																									 self.filter == NCDatabaseFilterUnpublished ? @" AND published=0" : @""]
																						resultBlock:block];
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
