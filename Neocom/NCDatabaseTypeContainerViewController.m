//
//  NCDatabaseTypeContainerViewController.m
//  Neocom
//
//  Created by Артем Шиманский on 15.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCDatabaseTypeContainerViewController.h"
#import "NCDatabaseTypeInfoViewController.h"
#import "NCDatabaseTypeMarketInfoViewController.h"
#import "UINavigationController+Neocom.h"

@interface NCDatabaseTypeContainerViewController ()
@property (nonatomic, strong) NCDatabaseTypeInfoViewController* typeInfoViewController;
@property (nonatomic, strong) NCDatabaseTypeMarketInfoViewController* typeMarketInfoViewController;
@end

@implementation NCDatabaseTypeContainerViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	self.typeInfoViewController = self.childViewControllers[0];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)onChangeMode:(id)sender {
	if (self.mode == NCDatabaseTypeContainerViewControllerModeTypeInfo)
		[self setMode:NCDatabaseTypeContainerViewControllerModeTypeMarketInfo animated:YES];
	else
		[self setMode:NCDatabaseTypeContainerViewControllerModeTypeInfo animated:YES];
}

- (void) setMode:(NCDatabaseTypeContainerViewControllerMode)mode {
	[self setMode:mode animated:NO];
}

- (void) setMode:(NCDatabaseTypeContainerViewControllerMode)mode animated:(BOOL) animated {
	if (mode == _mode)
		return;
	_mode = mode;
	
	void (^completion)(BOOL) = nil;
	
	UIViewController* from;
	UIViewController* to;
	if (mode == NCDatabaseTypeContainerViewControllerModeTypeInfo) {
		from = self.typeMarketInfoViewController;
		to = self.typeInfoViewController;
	}
	else {
		if (!self.typeMarketInfoViewController) {
			self.typeMarketInfoViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"NCDatabaseTypeMarketInfoViewController"];
			[self addChildViewController:self.typeMarketInfoViewController];
			[self.navigationController updateScrollViewFromViewController:self toViewController:self.typeMarketInfoViewController];

			completion = ^(BOOL finished) {
				[self.typeMarketInfoViewController didMoveToParentViewController:self];
			};
		}
		
		from = self.typeInfoViewController;
		to = self.typeMarketInfoViewController;
	}
	to.view.frame = from.view.frame;
	
	self.navigationItem.titleView = to.navigationItem.titleView;
	
	[self transitionFromViewController:from
					  toViewController:to
							  duration:0.0f
							   options:0
							animations:^{
							}
							completion:^(BOOL finished) {
								if (completion)
									completion(finished);
								[self.navigationController setViewControllers:self.navigationController.viewControllers];
							}];
}

@end
