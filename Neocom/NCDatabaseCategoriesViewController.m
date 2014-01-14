//
//  NCDatabaseCategoriesViewController.m
//  Neocom
//
//  Created by Артем Шиманский on 14.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCDatabaseCategoriesViewController.h"
#import "EVEDBAPI.h"

@interface NCDatabaseCategoriesViewController ()
@property (nonatomic, strong) NSArray* rows;
@end

@implementation NCDatabaseCategoriesViewController

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
	
	if (!self.rows) {
		NSMutableArray* rows = [NSMutableArray new];
		[[self taskManager] addTaskWithIndentifier:NCTaskManagerIdentifierNone
											 title:NCTaskManagerDefaultTitle
											 block:^(NCTask *task) {
												 [[EVEDBDatabase sharedDatabase] execSQLRequest:[NSString stringWithFormat:@"SELECT * FROM invCategories %@ ORDER BY categoryName",
																								 self.filter == NCDatabaseFilterPublished ? @"WHERE published=1":
																								 self.filter == NCDatabaseFilterUnpublished ? @"WHERE published=0" : @""]
																					resultBlock:^(sqlite3_stmt *stmt, BOOL *needsMore) {
																						[rows addObject:[[EVEDBInvCategory alloc] initWithStatement:stmt]];
																						if ([task isCancelled])
																							*needsMore = NO;
																					}];
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

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.rows.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
	EVEDBInvCategory* row = self.rows[indexPath.row];
	
	cell.textLabel.text = row.categoryName;
	
	if (row.icon.iconImageName)
		cell.imageView.image = [UIImage imageNamed:row.icon.iconImageName];
	else
		cell.imageView.image = [UIImage imageNamed:@"Icons/icon38_174.png"];
	
    return cell;
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

@end
