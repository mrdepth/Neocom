//
//  CertificateCategoriesViewController.m
//  EVEUniverse
//
//  Created by Mr. Depth on 1/25/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "CertificateCategoriesViewController.h"
#import "ItemCellView.h"
#import "NibTableViewCell.h"
#import "EVEDBAPI.h"
#import "EUOperationQueue.h"
#import "CertificatesViewController.h"

@implementation CertificateCategoriesViewController
@synthesize categoriesTableView;

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

- (void) dealloc {
	[categoriesTableView release];
	[rows release];
	[super dealloc];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	self.title = @"Certificates";
	
	NSMutableArray *rowsTmp = [NSMutableArray array];
	__block EUOperation *operation = [EUOperation operationWithIdentifier:@"MarketGroupsViewController+Load" name:@"Loading Categories"];
	[operation addExecutionBlock:^(void) {
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		
		[[EVEDBDatabase sharedDatabase] execWithSQLRequest:@"SELECT * FROM crtCategories ORDER BY categoryName;"
											   resultBlock:^(NSDictionary *record, BOOL *needsMore) {
												   [rowsTmp addObject:[EVEDBCrtCategory crtCategoryWithDictionary:record]];
												   if ([operation isCancelled])
													   *needsMore = NO;
											   }];
		[pool release];
	}];
	
	[operation setCompletionBlockInCurrentThread:^(void) {
		if (![operation isCancelled]) {
			[rows release];
			rows = [rowsTmp retain];
			[categoriesTableView reloadData];
		}
	}];
	
	[[EUOperationQueue sharedQueue] addOperation:operation];

}

- (void)viewDidUnload
{
    [super viewDidUnload];
	self.categoriesTableView = nil;
	[rows release];
	rows = nil;
}

// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		return UIInterfaceOrientationIsLandscape(interfaceOrientation);
	else
		return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return rows.count;
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *cellIdentifier = @"ItemCellView";
    
    ItemCellView *cell = (ItemCellView*) [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [ItemCellView cellWithNibName:@"ItemCellView" bundle:nil reuseIdentifier:cellIdentifier];
    }
	EVEDBCrtCategory *row = [rows objectAtIndex:indexPath.row];
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
	CertificatesViewController *controller = [[CertificatesViewController alloc] initWithNibName:(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? @"CertificatesViewController-iPad" : @"CertificatesViewController")
																		bundle:nil];
	controller.category = [rows objectAtIndex:indexPath.row];
	[self.navigationController pushViewController:controller animated:YES];
	[controller release];
}

@end
