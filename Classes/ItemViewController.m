//
//  ItemViewController.m
//  EVEUniverse
//
//  Created by Artem Shimanski on 2/2/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ItemViewController.h"
#import "ItemInfoViewController.h"
#import "MarketInfoViewController.h"
#import "EVEDBInvType.h"

@implementation ItemViewController
@synthesize itemInfoViewController;
@synthesize marketInfoViewController;
@synthesize parentView;
@synthesize activePage;
@synthesize type;
@synthesize pageSegmentControl;

// The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
/*
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization.
    }
    return self;
}
*/


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
	self.title = type.typeName;
	
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		self.navigationController.navigationBar.barStyle = UIBarStyleBlackOpaque;
		if ([[self.navigationController viewControllers] objectAtIndex:0] == self)
			[self.navigationItem setLeftBarButtonItem:[[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Close", nil) style:UIBarButtonItemStyleBordered target:self action:@selector(dismissModalViewController:)] autorelease]];
	}
	
	marketInfoViewController.type = type;
	itemInfoViewController.type = type;
	marketInfoViewController.parentViewController = self;
	
	if (activePage == ItemViewControllerActivePageInfo) {
		[parentView addSubview:itemInfoViewController.view];
		itemInfoViewController.view.frame = CGRectMake(0, 0, parentView.frame.size.width, parentView.frame.size.height);
		pageSegmentControl.selectedSegmentIndex = 0;
		if (type.marketGroupID != 0)
			[self.navigationItem setRightBarButtonItem:[[[UIBarButtonItem alloc] initWithCustomView:pageSegmentControl] autorelease]];
	}
	else {
		[parentView addSubview:marketInfoViewController.view];
		marketInfoViewController.view.frame = CGRectMake(0, 0, parentView.frame.size.width, parentView.frame.size.height);
		[self.navigationItem setRightBarButtonItem:[[[UIBarButtonItem alloc] initWithCustomView:pageSegmentControl] autorelease]];
		pageSegmentControl.selectedSegmentIndex = 1;
	}
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc. that aren't in use.
}

- (void)viewDidUnload {
    [super viewDidUnload];
	self.itemInfoViewController = nil;
	self.marketInfoViewController = nil;
	self.parentView = nil;
	self.pageSegmentControl = nil;
}


- (void)dealloc {
	[itemInfoViewController release];
	[marketInfoViewController release];
	[parentView release];
	[type release];
	[pageSegmentControl release];
    [super dealloc];
}

- (void) setActivePage:(ItemViewControllerActivePage) value animated:(BOOL) animated;{
	if (activePage == value)
		return;
	if (animated) {
		[UIView beginAnimations:nil context:nil];
		[UIView setAnimationBeginsFromCurrentState:YES];
		[UIView setAnimationTransition:(value == ItemViewControllerActivePageInfo ? UIViewAnimationTransitionFlipFromRight : UIViewAnimationTransitionFlipFromLeft)
							   forView:parentView cache:NO];
		[UIView setAnimationDuration:1];
	}
	activePage = value;

	if (activePage == ItemViewControllerActivePageInfo) {
		[marketInfoViewController.view removeFromSuperview];
		[parentView addSubview:itemInfoViewController.view];
		itemInfoViewController.view.frame = CGRectMake(0, 0, parentView.frame.size.width, parentView.frame.size.height);
		if (animated)
			[UIView commitAnimations];
	}
	else {
		[itemInfoViewController.view removeFromSuperview];
		[parentView addSubview:marketInfoViewController.view];
		marketInfoViewController.view.frame = CGRectMake(0, 0, parentView.frame.size.width, parentView.frame.size.height);
		if (animated)
			[UIView commitAnimations];
	}
	
}

- (void) setActivePage:(ItemViewControllerActivePage) value {
	[self setActivePage:value animated:NO];
}

- (IBAction) onChangePage:(id) sender {
	[self setActivePage:pageSegmentControl.selectedSegmentIndex == 0 ? ItemViewControllerActivePageInfo : ItemViewControllerActivePageMarket];
}

- (IBAction) dismissModalViewController:(id) sender {
	[self dismissModalViewControllerAnimated:YES];
}


@end
