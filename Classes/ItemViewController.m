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
	self.title = self.type.typeName;
	
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		self.navigationController.navigationBar.barStyle = UIBarStyleBlackOpaque;
		if ([[self.navigationController viewControllers] objectAtIndex:0] == self)
			[self.navigationItem setLeftBarButtonItem:[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Close", nil) style:UIBarButtonItemStyleBordered target:self action:@selector(dismiss)]];
	}
	
	self.marketInfoViewController.type = self.type;
	self.itemInfoViewController.type = self.type;
	
	if (self.activePage == ItemViewControllerActivePageInfo) {
		[self addChildViewController:self.itemInfoViewController];
		self.itemInfoViewController.view.frame = self.view.bounds;
		[self.view addSubview:self.itemInfoViewController.view];
		[self.itemInfoViewController didMoveToParentViewController:self];
		
		self.pageSegmentControl.selectedSegmentIndex = 0;
		if (self.type.marketGroupID != 0)
			[self.navigationItem setRightBarButtonItem:[[UIBarButtonItem alloc] initWithCustomView:self.pageSegmentControl]];
	}
	else {
		[self addChildViewController:self.marketInfoViewController];
		self.marketInfoViewController.view.frame = self.view.bounds;
		[self.view addSubview:self.marketInfoViewController.view];
		[self.marketInfoViewController didMoveToParentViewController:self];

		[self.navigationItem setRightBarButtonItem:[[UIBarButtonItem alloc] initWithCustomView:self.pageSegmentControl]];
		self.pageSegmentControl.selectedSegmentIndex = 1;
	}
}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		return YES;
	else
		return UIInterfaceOrientationIsPortrait(toInterfaceOrientation);
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
	self.pageSegmentControl = nil;
}

- (void) setActivePage:(ItemViewControllerActivePage) value {
	if (_activePage == value)
		return;
	_activePage = value;
	
	if ([self isViewLoaded]) {
		UIViewController* toAdd;
		UIViewController* toRemove;
		if (_activePage == ItemViewControllerActivePageInfo) {
			toAdd = self.itemInfoViewController;
			toRemove = self.marketInfoViewController;
		}
		else {
			toAdd = self.marketInfoViewController;
			toRemove = self.itemInfoViewController;
		}
		[toRemove.view removeFromSuperview];

		if (!toAdd.parentViewController) {
			[self addChildViewController:toAdd];
			[self.view addSubview:toAdd.view];
			toAdd.view.frame = self.view.bounds;
			[toAdd didMoveToParentViewController:self];
		}
		else {
			[self.view addSubview:toAdd.view];
			toAdd.view.frame = self.view.bounds;
		}
	}
}

- (IBAction) onChangePage:(id) sender {
	[self setActivePage:self.pageSegmentControl.selectedSegmentIndex == 0 ? ItemViewControllerActivePageInfo : ItemViewControllerActivePageMarket];
}

@end
