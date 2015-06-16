//
//  NCNavigationController.m
//  Neocom
//
//  Created by Артем Шиманский on 28.03.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCNavigationController.h"
#import "UIViewController+Neocom.h"
#import "NCPopoverController.h"

@interface NCNavigationController ()
@property (nonatomic, strong) UITapGestureRecognizer* tapOutsideGestureRecognizer;
- (void) onTap:(UITapGestureRecognizer *)recognizer;
@end

@implementation NCNavigationController

- (UIViewController*) viewControllerForUnwindSegueAction:(SEL)action fromViewController:(UIViewController *)fromViewController withSender:(id)sender {
	UIViewController* controller = [super viewControllerForUnwindSegueAction:action fromViewController:fromViewController withSender:sender];
	if (!controller)
		controller = [self.popover.presentingViewController viewControllerForUnwindSegueAction:action
																	  fromViewController:fromViewController
																			  withSender:sender];
	return controller;
}

- (UIStoryboardSegue*) segueForUnwindingToViewController:(UIViewController *)toViewController fromViewController:(UIViewController *)fromViewController identifier:(NSString *)identifier {
	if (fromViewController.parentViewController != toViewController.parentViewController) {
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
			if (fromViewController.popover) {
				return [UIStoryboardSegue segueWithIdentifier:identifier source:fromViewController destination:toViewController performHandler:^{
					[fromViewController.popover dismissPopoverAnimated:YES];
				}];
			}
			else if (fromViewController.modalPresentationStyle == UIModalPresentationPopover || fromViewController.parentViewController.modalPresentationStyle == UIModalPresentationPopover)
				return [UIStoryboardSegue segueWithIdentifier:identifier source:fromViewController destination:toViewController performHandler:^{
					[fromViewController dismissViewControllerAnimated:YES completion:nil];
				}];
		}
	}

	return [super segueForUnwindingToViewController:toViewController fromViewController:fromViewController identifier:identifier];
}

/*- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
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
    // Do any additional setup after loading the view.
}

- (void) viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	self.tapOutsideGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTap:)];
	self.tapOutsideGestureRecognizer.cancelsTouchesInView = NO;
}

- (void) viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	self.tapOutsideGestureRecognizer = nil;
}

- (void) dealloc {
	self.tapOutsideGestureRecognizer = nil;
}

- (void) viewDidLayoutSubviews {
	[super viewDidLayoutSubviews];
	UIView* v = self.view.subviews[0];
	v.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height - 100);
}

#pragma mark - Private

- (void) setTapOutsideGestureRecognizer:(UITapGestureRecognizer *)tapOutsideGestureRecognizer {
	if (_tapOutsideGestureRecognizer)
		[self.view.window removeGestureRecognizer:_tapOutsideGestureRecognizer];
	_tapOutsideGestureRecognizer = tapOutsideGestureRecognizer;
	if (tapOutsideGestureRecognizer)
		[self.view.window addGestureRecognizer:tapOutsideGestureRecognizer];
	
}

- (void) onTap:(UITapGestureRecognizer *)recognizer {
    if (recognizer.state == UIGestureRecognizerStateEnded) {
		//CGPoint location = [recognizer locationInView:nil];
		CGPoint location = [recognizer locationInView:self.view];
		
       // if (![self.view pointInside:[self.view convertPoint:location fromView:self.view.window] withEvent:nil]) {
		if (!CGRectContainsPoint(self.view.bounds, location)) {
			[self dismissViewControllerAnimated:YES completion:nil];
			self.tapOutsideGestureRecognizer = nil;
        }
	}
}*/

@end
