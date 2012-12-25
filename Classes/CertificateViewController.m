//
//  CertificateViewController.m
//  EVEUniverse
//
//  Created by Mr. Depth on 1/23/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "CertificateViewController.h"
#import "EVEDBAPI.h"
#import "ItemViewController.h"
#import "ItemCellView.h"
#import "UITableViewCell+Nib.h"
#import "EUOperationQueue.h"
#import "NSArray+GroupBy.h"

@implementation CertificateViewController
@synthesize scrollView;
@synthesize certificateTreeView;
@synthesize recommendationsTableView;
@synthesize contentView;
@synthesize certificate;
@synthesize pageSegmentControl;

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
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		self.navigationController.navigationBar.barStyle = UIBarStyleBlackOpaque;
		if ([[self.navigationController viewControllers] objectAtIndex:0] == self)
			[self.navigationItem setLeftBarButtonItem:[[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Close", nil) style:UIBarButtonItemStyleBordered target:self action:@selector(dismissModalViewController:)] autorelease]];
	}

	self.title = self.certificate.certificateClass.className;
	certificateTreeView.certificate = self.certificate;
    // Do any additional setup after loading the view from its nib.
}

- (void)viewDidUnload
{
    [self setCertificateTreeView:nil];
    [self setScrollView:nil];
	[self setRecommendationsTableView:nil];
	[self setContentView:nil];
	[sections release];
	sections = nil;
	[self setPageSegmentControl:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)dealloc {
    [certificateTreeView release];
    [scrollView release];
	[certificate release];
	[recommendationsTableView release];
	[contentView release];
	[sections release];
	[pageSegmentControl release];
    [super dealloc];
}

- (IBAction) dismissModalViewController:(id) sender {
	[self dismissModalViewControllerAnimated:YES];
}

- (IBAction) onSwitchScreens:(id)sender {
//	[UIView beginAnimations:nil context:nil];
//	[UIView setAnimationBeginsFromCurrentState:YES];
	UIView* currentView = [[contentView subviews] objectAtIndex:0];
//	[UIView setAnimationTransition:(currentView == scrollView ? UIViewAnimationTransitionFlipFromRight : UIViewAnimationTransitionFlipFromLeft)
//						   forView:contentView cache:NO];
	UIView* nextView = pageSegmentControl.selectedSegmentIndex == 0 ? scrollView : recommendationsTableView;
	if (currentView != nextView) {
		[currentView removeFromSuperview];
		[contentView addSubview:nextView];
		nextView.frame = contentView.bounds;
	}
//	[UIView setAnimationDuration:1];
//	[UIView commitAnimations];
//	[self.navigationItem setRightBarButtonItem:[[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:currentView == scrollView ? @"graphButton.png" : @"linesButton.png"] style:UIBarButtonItemStyleBordered target:self action:@selector(onSwitchScreens:)] autorelease]
//									  animated:YES];
}

#pragma mark UIScrollViewDelegate

- (UIView*) viewForZoomingInScrollView:(UIScrollView *)scrollView {
	return certificateTreeView;
}

#pragma mark CertificateTreeViewDelegate

- (void) certificateTreeViewDidFinishLoad:(CertificateTreeView*) aCertificateTreeView {
	scrollView.zoomScale = 1.0;
	scrollView.contentSize = certificateTreeView.frame.size;
	
	CGPoint offset = certificateTreeView.certificateView.center;
	offset.x -= scrollView.frame.size.width / 2.0;
	offset.y -= scrollView.frame.size.height / 2.0;
	offset.x = MAX(offset.x, 0.0);
	offset.y = MAX(offset.y, 0.0);
	scrollView.contentOffset = offset;
	
	float scaleX = scrollView.frame.size.width / certificateTreeView.frame.size.width;
	float scaleY = scrollView.frame.size.height / certificateTreeView.frame.size.height;
	scrollView.maximumZoomScale = 1;
	scrollView.minimumZoomScale = MIN(scaleX, scaleY);
	
	__block EUOperation* operation = [EUOperation operationWithIdentifier:@"CertificateViewController+load" name:NSLocalizedString(@"Loading Certificates", nil)];
	NSMutableArray* rowsTmp = [NSMutableArray array];
	NSMutableArray* sectionsTmp = [NSMutableArray array];
	[operation addExecutionBlock:^{
		NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
		for (EVEDBCrtRecommendation* recommendation in certificate.recommendations)
			[rowsTmp addObject:recommendation.shipType];
		[rowsTmp sortUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"typeName" ascending:YES]]];
		[sectionsTmp addObjectsFromArray:[rowsTmp arrayGroupedByKey:@"groupID"]];
		[sectionsTmp sortUsingComparator:^(id obj1, id obj2) {
			return [[[obj1 objectAtIndex:0] valueForKeyPath:@"group.groupName"] compare:[[obj2 objectAtIndex:0] valueForKeyPath:@"group.groupName"]];
		}];

		[pool release];
	}];
	
	[operation setCompletionBlockInCurrentThread:^{
		if (![operation isCancelled]) {
			//[rows release];
			//rows = [rowsTmp retain];
			[sections release];
			sections = [sectionsTmp retain];
			[recommendationsTableView reloadData];
			UIView* currentView = [[contentView subviews] objectAtIndex:0];
			if (currentView != scrollView) {
				[contentView addSubview:scrollView];
				scrollView.frame = contentView.bounds;
			}

			if (sections.count > 0)
				[self.navigationItem setRightBarButtonItem:[[[UIBarButtonItem alloc] initWithCustomView:pageSegmentControl] autorelease]];
				//self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"linesButton.png"] style:UIBarButtonItemStyleBordered target:self action:@selector(onSwitchScreens:)] autorelease];
				//self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"+" style:UIBarButtonItemStyleBordered target:self action:@selector(onSwitchScreens:)] autorelease];
			else {
				self.navigationItem.rightBarButtonItem = nil;
			}
		}
	}];
	
	[[EUOperationQueue sharedQueue] addOperation:operation];
}

- (void) certificateTreeView:(CertificateTreeView*) aCertificateTreeView didSelectCertificate:(EVEDBCrtCertificate*) aCertificate {
	self.certificate = aCertificate;
	certificateTreeView.certificate = aCertificate;
	self.title = self.certificate.certificateClass.className;

}

- (void) certificateTreeView:(CertificateTreeView*) aCertificateTreeView didSelectType:(EVEDBInvType*) type {
	ItemViewController *controller = [[ItemViewController alloc] initWithNibName:@"ItemViewController" bundle:nil];
	controller.type = type;
	[controller setActivePage:ItemViewControllerActivePageInfo];
	[self.navigationController pushViewController:controller animated:YES];
	[controller release];
}

#pragma mark -
#pragma mark Table view data source

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

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return sections.count;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return [[sections objectAtIndex:section] count];
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *cellIdentifier = @"ItemCellView";
    
    ItemCellView *cell = (ItemCellView*) [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [ItemCellView cellWithNibName:@"ItemCellView" bundle:nil reuseIdentifier:cellIdentifier];
    }
	EVEDBInvType *row = [[sections objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
	cell.titleLabel.text = row.typeName;
	cell.iconImageView.image = [UIImage imageNamed:[row typeSmallImageName]];
    return cell;
}

#pragma mark -
#pragma mark Table view delegate

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	return [[[sections objectAtIndex:section] objectAtIndex:0] valueForKeyPath:@"group.groupName"];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return 36;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	ItemViewController *controller = [[ItemViewController alloc] initWithNibName:@"ItemViewController" bundle:nil];
	controller.type = [[sections objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
	[controller setActivePage:ItemViewControllerActivePageInfo];
	[self.navigationController pushViewController:controller animated:YES];
	[controller release];
}

@end
