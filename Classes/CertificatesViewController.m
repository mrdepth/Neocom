//
//  CertificatesViewController.m
//  EVEUniverse
//
//  Created by Mr. Depth on 1/25/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "CertificatesViewController.h"
#import "GroupedCell.h"
#import "EVEDBAPI.h"
#import "EUOperationQueue.h"
#import "NSArray+GroupBy.h"
#import "EVEDBCrtCertificate+State.h"
#import "CertificateViewController.h"
#import "Globals.h"
#import "appearance.h"
#import "CollapsableTableHeaderView.h"
#import "UIView+Nib.h"

@interface CertificatesViewController()
@property (nonatomic, strong) NSMutableArray* sections;
- (void) reload;
- (void) didSelectAccount:(NSNotification*) notification;
@end

@implementation CertificatesViewController

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
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	self.view.backgroundColor = [UIColor colorWithNumber:AppearanceBackgroundColor];
	self.title = self.category.categoryName;
	[self reload];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didSelectAccount:) name:EVEAccountDidSelectNotification object:nil];
}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		return YES;
	else
		return UIInterfaceOrientationIsPortrait(toInterfaceOrientation);
}

- (void)viewDidUnload
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
    [super viewDidUnload];
	self.sections = nil;
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return self.sections.count;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return [[self.sections objectAtIndex:section] count];
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *cellIdentifier = @"Cell";
	
	GroupedCell* cell = (GroupedCell*) [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	if (cell == nil)
		cell = [[GroupedCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];//[ItemCellView cellWithNibName:@"ItemCellView" bundle:nil reuseIdentifier:cellIdentifier];
	
	EVEDBCrtCertificate *row = [[self.sections objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
	cell.textLabel.text = row.certificateClass.className;
	cell.imageView.image = [UIImage imageNamed:row.iconImageName];
	cell.accessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:row.stateIconImageName]];
	
	GroupedCellGroupStyle groupStyle = 0;
	if (indexPath.row == 0)
		groupStyle |= GroupedCellGroupStyleTop;
	if (indexPath.row == [self tableView:tableView numberOfRowsInSection:indexPath.section] - 1)
		groupStyle |= GroupedCellGroupStyleBottom;
	cell.groupStyle = groupStyle;
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	switch (section) {
		case 0:
			return NSLocalizedString(@"Basic", nil);
		case 1:
			return NSLocalizedString(@"Standard", nil);
		case 2:
			return NSLocalizedString(@"Improved", nil);
		case 3:
			return NSLocalizedString(@"Elite", nil);
		default:
			return NSLocalizedString(@"Unknown", nil);
	}
}

#pragma mark -
#pragma mark Table view delegate

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
	CollapsableTableHeaderView* view = [CollapsableTableHeaderView viewWithNibName:@"CollapsableTableHeaderView" bundle:nil];
	view.titleLabel.text = [self tableView:tableView titleForHeaderInSection:section];
	return view;
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
	return 22;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	
	CertificateViewController *controller = [[CertificateViewController alloc] initWithNibName:@"CertificateViewController" bundle:nil];
	controller.certificate = [[self.sections objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
	
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:controller];
		navController.modalPresentationStyle = UIModalPresentationFormSheet;
		[self presentViewController:navController animated:YES completion:nil];
	}
	else
		[self.navigationController pushViewController:controller animated:YES];
}

#pragma mark - Private

- (void) reload {
	NSMutableArray *sectionsTmp = [NSMutableArray array];
	__block EUOperation *operation = [EUOperation operationWithIdentifier:@"MarketGroupsViewController+Load" name:NSLocalizedString(@"Loading Certificates", nil)];
	__weak EUOperation* weakOperation = operation;
	[operation addExecutionBlock:^(void) {
		NSMutableArray* certificates = [NSMutableArray array];
		
		[[EVEDBDatabase sharedDatabase] execSQLRequest:[NSString stringWithFormat:@"SELECT * FROM crtCertificates WHERE categoryID = %d", self.category.categoryID]
											   resultBlock:^(sqlite3_stmt *stmt, BOOL *needsMore) {
												   [certificates addObject:[[EVEDBCrtCertificate alloc] initWithStatement:stmt]];
												   if ([weakOperation isCancelled])
													   *needsMore = NO;
											   }];
		weakOperation.progress = 0.5;
		[certificates sortUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"certificateClass.className" ascending:YES]]];
		
		if (![weakOperation isCancelled]) {
			[sectionsTmp addObjectsFromArray:[certificates arrayGroupedByKey:@"grade"]];
			[sectionsTmp sortUsingComparator:^(id obj1, id obj2) {
				return [[[obj1 objectAtIndex:0] valueForKeyPath:@"grade"] compare:[[obj2 objectAtIndex:0] valueForKeyPath:@"grade"]];
			}];
		}
	}];
	
	[operation setCompletionBlockInMainThread:^(void) {
		if (![weakOperation isCancelled]) {
			self.sections = sectionsTmp;
			[self.tableView reloadData];
		}
	}];
	
	[[EUOperationQueue sharedQueue] addOperation:operation];
}

- (void) didSelectAccount:(NSNotification*) notification {
	[self reload];
}

@end