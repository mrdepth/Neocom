//
//  CertificatesViewController.m
//  EVEUniverse
//
//  Created by Mr. Depth on 1/25/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "CertificatesViewController.h"
#import "CertificateCellView.h"
#import "NibTableViewCell.h"
#import "EVEDBAPI.h"
#import "EUOperationQueue.h"
#import "NSArray+GroupBy.h"
#import "EVEDBCrtCertificate+State.h"
#import "CertificateViewController.h"
#import "Globals.h"

@interface CertificatesViewController(Private)
- (void) reload;
- (void) didSelectAccount:(NSNotification*) notification;
@end

@implementation CertificatesViewController
@synthesize certificatesTableView;
@synthesize category;

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
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NotificationSelectAccount object:nil];
	[certificatesTableView release];
	[sections release];
	[category release];
	[super dealloc];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	self.title = category.categoryName;
	[self reload];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didSelectAccount:) name:NotificationSelectAccount object:nil];
}

- (void)viewDidUnload
{
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NotificationSelectAccount object:nil];
    [super viewDidUnload];
	self.certificatesTableView = nil;
	[sections release];
	sections = nil;
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
	return sections.count;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return [[sections objectAtIndex:section] count];
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *cellIdentifier = @"CertificateCellView";
    
    CertificateCellView *cell = (CertificateCellView*) [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [CertificateCellView cellWithNibName:@"CertificateCellView" bundle:nil reuseIdentifier:cellIdentifier];
    }
	EVEDBCrtCertificate *row = [[sections objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
	cell.titleLabel.text = row.certificateClass.className;
	cell.iconView.image = [UIImage imageNamed:row.iconImageName];
	cell.stateView.image = [UIImage imageNamed:row.stateIconImageName];
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	switch (section) {
		case 0:
			return @"Basic";
		case 1:
			return @"Standard";
		case 2:
			return @"Improved";
		case 3:
			return @"Elite";
		default:
			return @"Unknown";
	}
}

#pragma mark -
#pragma mark Table view delegate

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
	UIView *header = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 22)] autorelease];
	header.opaque = NO;
	header.backgroundColor = [UIColor colorWithRed:0.3 green:0.3 blue:0.3 alpha:0.9];
	
	UILabel *label = [[[UILabel alloc] initWithFrame:CGRectMake(10, 0, 300, 22)] autorelease];
	label.opaque = NO;
	label.backgroundColor = [UIColor clearColor];
	label.text = tableView == self.searchDisplayController.searchResultsTableView ? nil : [self tableView:tableView titleForHeaderInSection:section];
	label.textColor = [UIColor whiteColor];
	label.font = [label.font fontWithSize:12];
	label.shadowColor = [UIColor blackColor];
	label.shadowOffset = CGSizeMake(1, 1);
	[header addSubview:label];
	return header;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return 36;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	
	CertificateViewController *controller = [[CertificateViewController alloc] initWithNibName:(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? @"CertificateViewController-iPad" : @"CertificateViewController")
																		  bundle:nil];
	controller.certificate = [[sections objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
	
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:controller];
		navController.modalPresentationStyle = UIModalPresentationFormSheet;
		[self presentModalViewController:navController animated:YES];
		[navController release];
	}
	else
		[self.navigationController pushViewController:controller animated:YES];
	[controller release];
}

@end

@implementation CertificatesViewController(Private)

- (void) reload {
	NSMutableArray *sectionsTmp = [NSMutableArray array];
	__block EUOperation *operation = [EUOperation operationWithIdentifier:@"MarketGroupsViewController+Load" name:@"Loading Certificates"];
	[operation addExecutionBlock:^(void) {
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		NSMutableArray* certificates = [NSMutableArray array];
		
		[[EVEDBDatabase sharedDatabase] execWithSQLRequest:[NSString stringWithFormat:@"SELECT * FROM crtCertificates WHERE categoryID = %d", category.categoryID]
											   resultBlock:^(NSDictionary *record, BOOL *needsMore) {
												   [certificates addObject:[EVEDBCrtCertificate crtCertificateWithDictionary:record]];
												   if ([operation isCancelled])
													   *needsMore = NO;
											   }];
		operation.progress = 0.5;
		[certificates sortUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"certificateClass.className" ascending:YES]]];
		
		if (![operation isCancelled]) {
			[sectionsTmp addObjectsFromArray:[certificates arrayGroupedByKey:@"grade"]];
			[sectionsTmp sortUsingComparator:^(id obj1, id obj2) {
				return [[[obj1 objectAtIndex:0] valueForKeyPath:@"grade"] compare:[[obj2 objectAtIndex:0] valueForKeyPath:@"grade"]];
			}];
		}
		
		[pool release];
	}];
	
	[operation setCompletionBlockInCurrentThread:^(void) {
		if (![operation isCancelled]) {
			[sections release];
			sections = [sectionsTmp retain];
			[certificatesTableView reloadData];
		}
	}];
	
	[[EUOperationQueue sharedQueue] addOperation:operation];
}

- (void) didSelectAccount:(NSNotification*) notification {
	[self reload];
}

@end