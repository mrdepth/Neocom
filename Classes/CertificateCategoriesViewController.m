//
//  CertificateCategoriesViewController.m
//  EVEUniverse
//
//  Created by Mr. Depth on 1/25/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "CertificateCategoriesViewController.h"
#import "GroupedCell.h"
#import "EVEDBAPI.h"
#import "EUOperationQueue.h"
#import "CertificatesViewController.h"
#import "appearance.h"

@interface CertificateCategoriesViewController()
@property (nonatomic, strong) NSMutableArray* rows;

@end

@implementation CertificateCategoriesViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	self.view.backgroundColor = [UIColor colorWithNumber:AppearanceBackgroundColor];
	self.title = NSLocalizedString(@"Certificates", nil);
	
	NSMutableArray *rowsTmp = [NSMutableArray array];
	__block EUOperation *operation = [EUOperation operationWithIdentifier:@"MarketGroupsViewController+Load" name:NSLocalizedString(@"Loading Certificates...", nil)];
	__weak EUOperation* weakOperation = operation;
	[operation addExecutionBlock:^(void) {
		[[EVEDBDatabase sharedDatabase] execSQLRequest:@"SELECT * FROM crtCategories ORDER BY categoryName;"
											   resultBlock:^(sqlite3_stmt *stmt, BOOL *needsMore) {
												   [rowsTmp addObject:[[EVEDBCrtCategory alloc] initWithStatement:stmt]];
												   if ([weakOperation isCancelled])
													   *needsMore = NO;
											   }];
	}];
	
	[operation setCompletionBlockInMainThread:^(void) {
		if (![weakOperation isCancelled]) {
			self.rows = rowsTmp;
			[self.tableView reloadData];
		}
	}];
	
	[[EUOperationQueue sharedQueue] addOperation:operation];

}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		return YES;
	else
		return UIInterfaceOrientationIsPortrait(toInterfaceOrientation);
}

- (void)viewDidUnload
{
    [super viewDidUnload];
	self.rows = nil;
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return self.rows.count;
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *cellIdentifier = @"Cell";
	
	GroupedCell* cell = (GroupedCell*) [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	if (cell == nil) {
		cell = [[GroupedCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];//[ItemCellView cellWithNibName:@"ItemCellView" bundle:nil reuseIdentifier:cellIdentifier];
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	}
	
	EVEDBCrtCategory *row = [self.rows objectAtIndex:indexPath.row];
	cell.textLabel.text = row.categoryName;
	cell.imageView.image = [UIImage imageNamed:@"Icons/icon79_06.png"];
	
	GroupedCellGroupStyle groupStyle = 0;
	if (indexPath.row == 0)
		groupStyle |= GroupedCellGroupStyleTop;
	if (indexPath.row == [self tableView:tableView numberOfRowsInSection:indexPath.section] - 1)
		groupStyle |= GroupedCellGroupStyleBottom;
	cell.groupStyle = groupStyle;
    return cell;
}

#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	CertificatesViewController *controller = [[CertificatesViewController alloc] initWithNibName:@"CertificatesViewController" bundle:nil];
	controller.category = [self.rows objectAtIndex:indexPath.row];
	[self.navigationController pushViewController:controller animated:YES];
}

@end
