//
//  UIViewController+Neocom.m
//  Neocom
//
//  Created by Shimanski Artem on 28.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "UIViewController+Neocom.h"
#import <objc/runtime.h>

@interface NCPopoverController : UIPopoverController

@end

@interface UIViewController()<UIPopoverControllerDelegate>
@property (nonatomic, strong) UIPopoverController* popover;

@end

@implementation NCPopoverController

- (void) dismissPopoverAnimated:(BOOL)animated {
	[super dismissPopoverAnimated:animated];
	self.contentViewController.popover = nil;
}

@end

@implementation UIViewController (Neocom)

- (void) dismiss {
	if (self.popover)
		[self.popover dismissPopoverAnimated:YES];
	else
		[self dismissViewControllerAnimated:YES completion:nil];
}

- (void) setPopover:(UIPopoverController *)popover {
	objc_setAssociatedObject(self, @"popover", popover, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIPopoverController*) popover {
	return objc_getAssociatedObject(self, @"popover");
}

- (void)presentViewControllerInPopover:(UIViewController *)viewControllerToPresent fromRect:(CGRect) rect inView:(UIView*) view permittedArrowDirections:(UIPopoverArrowDirection)arrowDirections animated:(BOOL)animated {
	self.popover = [[NCPopoverController alloc] initWithContentViewController:viewControllerToPresent];
	self.popover.delegate = self;
	[self.popover presentPopoverFromRect:rect inView:view permittedArrowDirections:UIPopoverArrowDirectionAny animated:animated];
}

- (void)presentViewControllerInPopover:(UIViewController *)viewControllerToPresent fromBarButtonItem:(UIBarButtonItem *)item permittedArrowDirections:(UIPopoverArrowDirection)arrowDirections animated:(BOOL)animated {
	if (self.popover)
		[self.popover dismissPopoverAnimated:YES];
	
	self.popover = [[NCPopoverController alloc] initWithContentViewController:viewControllerToPresent];
	self.popover.delegate = self;
	[self.popover presentPopoverFromBarButtonItem:item permittedArrowDirections:arrowDirections animated:animated];
}

- (IBAction)dismissAnimated {
	if (self.popover)
		[self.popover dismissPopoverAnimated:YES];
	else
		[self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UIPopoverControllerDelegate

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController {
	if (self.popover == popoverController)
		self.popover = nil;
}

@end
