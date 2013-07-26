//
//  CertificateCategoriesViewController.m
//  EVEUniverse
//
//  Created by Mr. Depth on 1/25/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "CertificateCategoriesViewController.h"
#import "ItemCellView.h"
#import "UITableViewCell+Nib.h"
#import "EVEDBAPI.h"
#import "EUOperationQueue.h"
#import "CertificatesViewController.h"

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
	self.tableView.backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"background.png"]];
	self.title = NSLocalizedString(@"Certificates", nil);
	
	NSMutableArray *rowsTmp = [NSMutableArray array];
	__block EUOperation *operation = [EUOperation operationWithIdentifier:@"MarketGroupsViewController+Load" name:NSLocalizedString(@"Loading Categories", nil)];
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
    
    static NSString *cellIdentifier = @"ItemCellView";
    
    ItemCellView *cell = (ItemCellView*) [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [ItemCellView cellWithNibName:@"ItemCellView" bundle:nil reuseIdentifier:cellIdentifier];
    }
	EVEDBCrtCategory *row = [self.rows objectAtIndex:indexPath.row];
	cell.titleLabel.text = row.categoryName;
	cell.iconImageView.image = [UIImage imageNamed:@"Icons/icon79_06.png"];
    return cell;
}

#pragma mark -
#pragma mark Table view delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return 36;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	CertificatesViewController *controller = [[CertificatesViewController alloc] initWithNibName:@"CertificatesViewController" bundle:nil];
	controller.category = [self.rows objectAtIndex:indexPath.row];
	[self.navigationController pushViewController:controller animated:YES];
}

@end
