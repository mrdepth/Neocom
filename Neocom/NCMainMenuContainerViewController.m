//
//  NCMainMenuContainerViewController.m
//  Neocom
//
//  Created by Артем Шиманский on 09.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCMainMenuContainerViewController.h"
#import "UIView+Nib.h"
#import "NCNavigationCharacterButton.h"
#import "NCSideMenuViewController.h"

@interface NCMainMenuDropDownSegue: UIStoryboardSegue

@end

@interface NCMainMenuContainerViewController ()
@property (nonatomic, strong) NCNavigationCharacterButton* navigationCharacterButton;
@property (nonatomic, strong) UIViewController* dropDownViewController;
@property (nonatomic, strong) UIViewController* menuViewController;

- (void) presentDropDownViewController:(UIViewController *)dropDownViewController animated:(BOOL) animated;
- (void) dismissDropDownViewControllerAnimated:(BOOL) animated;
- (IBAction)onAccounts:(id)sender;
@end

@implementation NCMainMenuDropDownSegue

- (void) perform {
	NCMainMenuContainerViewController* sourceViewController = self.sourceViewController;
	[sourceViewController presentDropDownViewController:self.destinationViewController animated:YES];
}

@end



@implementation NCMainMenuContainerViewController

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
	
	self.menuViewController = self.childViewControllers[0];
	
	self.navigationCharacterButton = [NCNavigationCharacterButton viewWithNibName:@"NCNavigationCharacterButton" bundle:nil];
	[self.navigationCharacterButton addTarget:self action:@selector(onAccounts:) forControlEvents:UIControlEventTouchUpInside];
	CGRect frame = self.navigationCharacterButton.frame;
	frame.origin.x = 10;
	frame.origin.y = self.navigationController.navigationBar.frame.size.height - frame.size.height;
	self.navigationCharacterButton.frame = frame;
	[self.navigationController.navigationBar addSubview:self.navigationCharacterButton];
	self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.navigationCharacterButton];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)unwindToMainMenu:(UIStoryboardSegue*)sender {
	[self dismissDropDownViewControllerAnimated:YES];
}

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	if ([keyPath isEqualToString:@"rightBarButtonItem"]) {
		[self.navigationItem setRightBarButtonItem:[object valueForKey:keyPath] animated:YES];
	}
}

#pragma mark - Private

- (void) presentDropDownViewController:(UIViewController *)dropDownViewController animated:(BOOL) animated {
	if (dropDownViewController) {
		if (self.dropDownViewController)
			[self.dropDownViewController.navigationItem removeObserver:self forKeyPath:@"rightBarButtonItem"];

		self.dropDownViewController = dropDownViewController;
		
		[self.navigationItem setRightBarButtonItem:dropDownViewController.navigationItem.rightBarButtonItem animated:YES];
		[dropDownViewController.navigationItem addObserver:self forKeyPath:@"rightBarButtonItem" options:NSKeyValueObservingOptionNew context:nil];

		CGRect frame = self.menuViewController.view.superview.bounds;
		dropDownViewController.view.frame = frame;
		dropDownViewController.view.layer.zPosition = 1.0;
		dropDownViewController.view.transform = CGAffineTransformMakeTranslation(0.0f, -frame.size.height);
		dropDownViewController.view.translatesAutoresizingMaskIntoConstraints = YES;
		dropDownViewController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		
		[self addChildViewController:dropDownViewController];
		self.navigationCharacterButton.userInteractionEnabled = NO;
		[self transitionFromViewController:self.menuViewController
						  toViewController:self.dropDownViewController
								  duration:animated ? NCMainMenuDropDownSegueAnimationDuration : 0.0f
								   options:UIViewAnimationOptionAllowAnimatedContent
								animations:^{
									dropDownViewController.view.transform = CGAffineTransformIdentity;
/*									if ([dropDownViewController.view isKindOfClass:[UIScrollView class]]) {
										UIScrollView* scrollView = (UIScrollView*) dropDownViewController.view;
										UITableViewController* menuViewController = (UITableViewController*) self.menuViewController;
										scrollView.contentInset = menuViewController.tableView.contentInset;
									}*/
								}
								completion:^(BOOL finished) {
									[dropDownViewController didMoveToParentViewController:self];
									self.navigationCharacterButton.userInteractionEnabled = YES;
								}];
		
		[self.sideMenuViewController setFullScreen:YES animated:animated];
		self.navigationCharacterButton.selected = YES;
	}
}

- (void) dismissDropDownViewControllerAnimated:(BOOL) animated {
	if (self.dropDownViewController) {
		[self.dropDownViewController.navigationItem removeObserver:self forKeyPath:@"rightBarButtonItem"];
		[self.navigationItem setRightBarButtonItem:nil animated:YES];

		[self.dropDownViewController willMoveToParentViewController:nil];
		self.navigationCharacterButton.userInteractionEnabled = NO;
		
		UIViewController* dropDownViewController = self.dropDownViewController;
		
		[self transitionFromViewController:dropDownViewController
						  toViewController:self.menuViewController
								  duration:animated ? NCMainMenuDropDownSegueAnimationDuration : 0.0f
								   options:0
								animations:^{
									if (animated)
										dropDownViewController.view.transform = CGAffineTransformMakeTranslation(0, -dropDownViewController.view.frame.size.height);
								}
								completion:^(BOOL finished) {
									self.navigationCharacterButton.userInteractionEnabled = YES;
									[dropDownViewController removeFromParentViewController];
								}];
		self.dropDownViewController = nil;
		self.navigationCharacterButton.selected = NO;
		[self.sideMenuViewController setFullScreen:NO animated:animated];
	}
}

- (IBAction)onAccounts:(id)sender {
	if (self.dropDownViewController) {
		[self dismissDropDownViewControllerAnimated:YES];
	}
	else {
		[self performSegueWithIdentifier:@"NCMainMenuDropDownSegue" sender:nil];
	}
}


@end
