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
	self.navigationCharacterButton = [NCNavigationCharacterButton viewWithNibName:@"NCNavigationCharacterButton" bundle:nil];
	[self.navigationCharacterButton addTarget:self action:@selector(onAccounts:) forControlEvents:UIControlEventTouchUpInside];
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
		if (self.dropDownViewController) {
			[self dismissDropDownViewControllerAnimated:YES];
			return;
		}
		
		_dropDownViewController = dropDownViewController;
		[self addChildViewController:dropDownViewController];
		__block CGRect frame = self.view.bounds;
		CGFloat navigationBarHeight = CGRectGetMaxY(self.navigationController.navigationBar.frame);
		navigationBarHeight = 0;
		frame.size.height -= navigationBarHeight;
		frame.origin.y = navigationBarHeight;
		dropDownViewController.view.frame = frame;
		
		[dropDownViewController beginAppearanceTransition:YES animated:animated];
		[self.view addSubview:dropDownViewController.view];
		NSMutableArray* items = [NSMutableArray arrayWithArray:self.navigationController.navigationBar.items];
		[items addObject:dropDownViewController.navigationItem];
		dropDownViewController.navigationItem.hidesBackButton = YES;

		[self.navigationController.navigationBar setItems:items animated:YES];
		
		if (animated) {
			dropDownViewController.view.transform = CGAffineTransformMakeTranslation(0.0f, -frame.size.height);
			self.navigationCharacterButton.userInteractionEnabled = NO;
			[UIView transitionWithView:self.view
							  duration:NCMainMenuDropDownSegueAnimationDuration
							   options:UIViewAnimationOptionAllowAnimatedContent | UIViewAnimationOptionCurveEaseIn
							animations:^{
								dropDownViewController.view.transform = CGAffineTransformMakeTranslation(0.0f, 10.0f);
							}
							completion:^(BOOL finished) {
								[UIView transitionWithView:self.view
												  duration:0.15f
												   options:UIViewAnimationOptionAllowAnimatedContent
												animations:^{
													dropDownViewController.view.transform = CGAffineTransformMakeTranslation(0.0f, -5.0f);
												}
												completion:^(BOOL finished) {
													[UIView transitionWithView:self.view
																	  duration:0.1f
																	   options:UIViewAnimationOptionAllowAnimatedContent
																	animations:^{
																		dropDownViewController.view.transform = CGAffineTransformIdentity;
																	}
																	completion:^(BOOL finished) {
																		[dropDownViewController didMoveToParentViewController:self];
																		[dropDownViewController endAppearanceTransition];
																		self.navigationCharacterButton.userInteractionEnabled = YES;
																	}];
												}];
							}];
		}
		else {
			[dropDownViewController didMoveToParentViewController:self];
		}
		
		[self.sideMenuViewController setFullScreen:YES animated:animated];
		self.navigationCharacterButton.selected = YES;
	}
}

- (void) dismissDropDownViewControllerAnimated:(BOOL) animated {
	if (_dropDownViewController) {
		NSMutableArray* items = [NSMutableArray arrayWithArray:self.navigationController.navigationBar.items];
		[items removeLastObject];
		[self.navigationController.navigationBar setItems:items animated:YES];

		
		[_dropDownViewController willMoveToParentViewController:nil];
		if (animated) {
			UIViewController* viewController = _dropDownViewController;
			self.navigationCharacterButton.userInteractionEnabled = NO;

			[UIView transitionWithView:self.view
							  duration:NCMainMenuDropDownSegueAnimationDuration
							   options:UIViewAnimationOptionCurveEaseIn
							animations:^{
								viewController.view.transform = CGAffineTransformMakeTranslation(0.0f, -viewController.view.frame.size.height);
							}
							completion:^(BOOL finished) {
								[viewController.view removeFromSuperview];
								[viewController removeFromParentViewController];
								self.navigationCharacterButton.userInteractionEnabled = YES;
							}];
		}
		else {
			[_dropDownViewController.view removeFromSuperview];
			[_dropDownViewController removeFromParentViewController];
		}
		_dropDownViewController = nil;
		
		[self.sideMenuViewController setFullScreen:NO animated:animated];
		self.navigationCharacterButton.selected = NO;
	}
}

- (IBAction)onAccounts:(id)sender {
	if (self.dropDownViewController) {
		[self dismissDropDownViewControllerAnimated:YES];
		//self.navigationCharacterButton.selected = NO;
		//[self.sideMenuViewController setFullScreen:NO animated:YES];
		//[self.dropDownViewController dismissViewControllerAnimated:YES completion:nil];
	}
	else {
		[self performSegueWithIdentifier:@"NCMainMenuDropDownSegue" sender:nil];
		//[self.sideMenuViewController setFullScreen:YES animated:YES];
	}
}


@end
