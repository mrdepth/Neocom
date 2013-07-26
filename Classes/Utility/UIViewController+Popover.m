//
//  UIViewController+Popover.m
//  EVEUniverse
//
//  Created by mr_depth on 22.07.13.
//
//

#import "UIViewController+Popover.h"
#import <objc/runtime.h>

@interface UIViewController()<UIPopoverControllerDelegate>
@property (nonatomic, strong) UIPopoverController* popover;

@end

@implementation UIViewController (Popover)

- (void) setPopover:(UIPopoverController *)popover {
	objc_setAssociatedObject(self, @"popover", popover, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIPopoverController*) popover {
	return objc_getAssociatedObject(self, @"popover");
}

- (void)presentViewControllerInPopover:(UIViewController *)viewControllerToPresent fromBarButtonItem:(UIBarButtonItem *)item permittedArrowDirections:(UIPopoverArrowDirection)arrowDirections animated:(BOOL)animated {
	self.popover = [[UIPopoverController alloc] initWithContentViewController:viewControllerToPresent];
	self.popover.delegate = self;
	[self.popover presentPopoverFromBarButtonItem:item permittedArrowDirections:arrowDirections animated:animated];
}

- (void)presentViewControllerInPopover:(UIViewController *)viewControllerToPresent fromRect:(CGRect) rect inView:(UIView*) view permittedArrowDirections:(UIPopoverArrowDirection)arrowDirections animated:(BOOL)animated {
	self.popover = [[UIPopoverController alloc] initWithContentViewController:viewControllerToPresent];
	self.popover.delegate = self;
	[self.popover presentPopoverFromRect:rect inView:view permittedArrowDirections:arrowDirections animated:animated];
}

#pragma mark - UIPopoverControllerDelegate

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController {
	self.popover = nil;
}

@end
