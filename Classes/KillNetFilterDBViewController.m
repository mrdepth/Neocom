//
//  KillNetFilterDBViewController.m
//  EVEUniverse
//
//  Created by Artem Shimanski on 14.11.12.
//
//

#import "KillNetFilterDBViewController.h"
#import "EVEDBAPI.h"
#import "EUOperationQueue.h"
#import "TitleCellView.h"
#import "UITableViewCell+Nib.h"

@interface KillNetFilterDBViewController ()
@property (nonatomic, strong) NSArray* rows;
@property (nonatomic, strong) NSArray* filteredRows;
@property (nonatomic, weak) KillNetFilterDBViewController* parent;

- (void) reload;
- (void) searchWithSearchString:(NSString*) searchString;
@end

@implementation KillNetFilterDBViewController

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
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		self.tableView.backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"backgroundPopover~ipad.png"]];
		self.tableView.backgroundView.contentMode = UIViewContentModeTop;
	}
	else
		self.tableView.backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"background.png"]];
	[self reload];
}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		return YES;
	else
		return UIInterfaceOrientationIsPortrait(toInterfaceOrientation);
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
	if (self.searchDisplayController.searchResultsTableView == tableView)
		return self.filteredRows.count;
	else
		return self.rows.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"TitleCellView";
    TitleCellView *cell = (TitleCellView*) [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil)
        cell = [TitleCellView cellWithNibName:@"TitleCellView" bundle:nil reuseIdentifier:CellIdentifier];
	NSDictionary* row = self.searchDisplayController.searchResultsTableView == tableView ? [self.filteredRows objectAtIndex:indexPath.row] : [self.rows objectAtIndex:indexPath.row];
	NSString* groupName = [row valueForKey:@"groupName"];
	if (groupName && self.searchDisplayController.searchResultsTableView == tableView && !self.groupID && self.groupsRequest)
		cell.titleLabel.text = [NSString stringWithFormat:@"%@ < %@", [row valueForKey:@"name"], groupName];
	else
		cell.titleLabel.text = [row valueForKey:@"name"];

	
	if (self.groupsRequest && !self.groupID && self.searchDisplayController.searchResultsTableView != tableView)
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	else
		cell.accessoryType = UITableViewCellAccessoryNone;
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


#pragma mark - Table view delegate

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return 32;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSDictionary* row = self.searchDisplayController.searchResultsTableView == tableView ? [self.filteredRows objectAtIndex:indexPath.row] : [self.rows objectAtIndex:indexPath.row];
	if (self.groupsRequest && !self.groupID && self.searchDisplayController.searchResultsTableView != tableView) {
		KillNetFilterDBViewController* controller = [[KillNetFilterDBViewController alloc] initWithNibName:@"KillNetFilterDBViewController" bundle:nil];
		controller.groupsRequest = self.groupsRequest;
		controller.itemsRequest = self.itemsRequest;
		controller.searchRequest = self.searchRequest;
		controller.groupID = [[row valueForKey:@"itemID"] integerValue];
		controller.groupName = self.groupName;
		controller.parent = self;
		controller.delegate = self.delegate;
		controller.title = [row valueForKey:@"name"];
		[self.navigationController pushViewController:controller animated:YES];
	}
	else {
		[self.delegate killNetFilterDBViewController:(self.parent ? self.parent : self) didSelectItem:row];
	}
}

#pragma mark -
#pragma mark UISearchDisplayController Delegate Methods

- (BOOL) searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString {
	//[self filter];
	[self searchWithSearchString:searchString];
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


#pragma mark - Private

- (void) reload {
	NSMutableArray *rowsTmp = [NSMutableArray array];
	
	__block EUOperation *operation = [EUOperation operationWithIdentifier:@"KillNetFilterDBViewController+Load" name:NSLocalizedString(@"Loading...", nil)];
	__weak EUOperation* weakOperation = operation;
	[operation addExecutionBlock:^(void) {
		@autoreleasepool {
			if ([weakOperation isCancelled])
				return;
			NSMutableString* request = [NSMutableString string];
			if (!self.groupID && self.groupsRequest)
				[request setString:self.groupsRequest];
			else {
				if (self.groupID)
					[request appendFormat:self.itemsRequest, [NSString stringWithFormat:@"AND %@=%d", self.groupName, self.groupID]];
				else
					[request appendFormat:self.itemsRequest, @""];
			}
			
			[[EVEDBDatabase sharedDatabase] execSQLRequest:request
												   resultBlock:^(sqlite3_stmt *stmt, BOOL *needsMore) {
													   [rowsTmp addObject:[NSDictionary dictionaryWithStatement:stmt]];
												   }];
			weakOperation.progress = 0.75;
		}
	}];
	
	[operation setCompletionBlockInCurrentThread:^(void) {
		self.rows = rowsTmp;
		[self.tableView reloadData];
	}];
	
	[[EUOperationQueue sharedQueue] addOperation:operation];
}

- (void) searchWithSearchString:(NSString*) searchString {
	if (searchString.length == 0)
		return;
	
	NSMutableArray *rowsTmp = [NSMutableArray array];
	
	__block EUOperation *operation = [EUOperation operationWithIdentifier:@"KillNetFilterDBViewController+Search" name:NSLocalizedString(@"Searching...", nil)];
	__weak EUOperation* weakOperation = operation;
	[operation addExecutionBlock:^(void) {
		@autoreleasepool {
			if ([weakOperation isCancelled])
				return;
			NSMutableString* where = [NSMutableString stringWithFormat:@"AND %@", [NSString stringWithFormat:self.searchRequest, searchString]];
			if (self.groupID)
				[where appendFormat:@" AND %@=%d", self.groupName, self.groupID];
			[[EVEDBDatabase sharedDatabase] execSQLRequest:[NSString stringWithFormat:self.itemsRequest, where]
											   resultBlock:^(sqlite3_stmt *stmt, BOOL *needsMore) {
												   if ([weakOperation isCancelled])
													   *needsMore = NO;
												   [rowsTmp addObject:[NSDictionary dictionaryWithStatement:stmt]];
											   }];
			weakOperation.progress = 0.75;
		}
	}];
	
	[operation setCompletionBlockInCurrentThread:^(void) {
		if (![weakOperation isCancelled]) {
			self.filteredRows = rowsTmp;
			[self.searchDisplayController.searchResultsTableView reloadData];
		}
	}];
	
	[[EUOperationQueue sharedQueue] addOperation:operation];
}

@end
