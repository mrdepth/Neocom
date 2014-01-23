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
#import "UINavigationController+Neocom.h"

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
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)unwindToMainMenu:(UIStoryboardSegue*)sender {
	[self dismissDropDownViewControllerAnimated:YES];
}

#pragma mark - Private

- (void) presentDropDownViewController:(UIViewController *)dropDownViewController animated:(BOOL) animated {
	if (dropDownViewController) {
		self.dropDownViewController = dropDownViewController;
		
		NSMutableArray* items = [NSMutableArray arrayWithArray:self.navigationController.navigationBar.items];
		self.dropDownViewController.navigationItem.hidesBackButton = YES;
		[items addObject:self.dropDownViewController.navigationItem];
		[self.navigationController.navigationBar setItems:items animated:YES];

		CGRect frame = self.view.bounds;
		dropDownViewController.view.frame = frame;
		dropDownViewController.view.layer.zPosition = 1.0;
		dropDownViewController.view.transform = CGAffineTransformMakeTranslation(0.0f, -frame.size.height);
		
		[self addChildViewController:dropDownViewController];
		self.navigationCharacterButton.userInteractionEnabled = NO;
		[self transitionFromViewController:self.menuViewController
						  toViewController:self.dropDownViewController
								  duration:animated ? NCMainMenuDropDownSegueAnimationDuration : 0.0f
								   options:UIViewAnimationOptionAllowAnimatedContent
								animations:^{
/*									if (animated) {
										CAKeyframeAnimation* animation = [CAKeyframeAnimation animationWithKeyPath:@"transform"];
										animation.keyTimes = @[@(0.0), @(0.6), @(0.8), @(1.0)];
										animation.values = @[[NSValue valueWithCATransform3D:CATransform3DMakeTranslation(0.0f, -frame.size.height, 0.0f)],
															 [NSValue valueWithCATransform3D:CATransform3DMakeTranslation(0.0f, 10.0f, 0.0f)],
															 [NSValue valueWithCATransform3D:CATransform3DMakeTranslation(0.0f, -5.0f, 0.0f)],
															 [NSValue valueWithCATransform3D:CATransform3DIdentity]];
										animation.duration = 0.5f;
										[dropDownViewController.view.layer addAnimation:animation forKey:@"transform"];
									}*/
									dropDownViewController.view.transform = CGAffineTransformIdentity;
									[self.navigationController updateScrollViewFromViewController:self toViewController:self.dropDownViewController];
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
		NSMutableArray* items = [NSMutableArray arrayWithArray:self.navigationController.navigationBar.items];
		[items removeLastObject];
		[self.navigationController.navigationBar setItems:items animated:YES];

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
