//
//  UIViewController+Neocom.m
//  Neocom
//
//  Created by Shimanski Artem on 28.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "UIViewController+Neocom.h"
#import <objc/runtime.h>
#import "UIColor+Neocom.h"
#import "NCPopoverController.h"

/*@interface NCPopoverController : UIPopoverController

@end

@interface UIViewController()<UIPopoverControllerDelegate>
@property (nonatomic, strong) UIPopoverController* popover;

@end

@implementation NCPopoverController

- (void) dismissPopoverAnimated:(BOOL)animated {
	[super dismissPopoverAnimated:animated];
	self.contentViewController.popover = nil;
}

@end*/

@implementation UIViewController (Neocom)

- (UIStatusBarStyle) preferredStatusBarStyle {
	return UIStatusBarStyleLightContent;
}


- (void) dismiss {
	if (self.popover)
		[self.popover dismissPopoverAnimated:YES];
	else
		[self dismissViewControllerAnimated:YES completion:nil];
}

- (NCPopoverController*) popover {
	NCPopoverController* popover = objc_getAssociatedObject(self, @"popover");
	if (!popover)
		popover = self.parentViewController.popover;
	return popover;
}

- (void) setPopover:(NCPopoverController *)popover {
	objc_setAssociatedObject(self, @"popover", popover, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (IBAction)dismissAnimated {
	if (self.popover)
		[self.popover dismissPopoverAnimated:YES];
	else
		[self dismissViewControllerAnimated:YES completion:nil];
}

- (void) presentViewControllerInPopover:(UIViewController *)viewControllerToPresent withSender:(id) sender animated:(BOOL)animated {
    if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_7_1) {
        NCPopoverController* popoverController = [[NCPopoverController alloc] initWithContentViewController:viewControllerToPresent];
		popoverController.presentingViewController = self;
        popoverController.backgroundColor = [UIColor appearancePopoverBackgroundColor];
        if ([sender isKindOfClass:[UIBarButtonItem class]])
            [popoverController presentPopoverFromBarButtonItem:sender permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
        else
            [popoverController presentPopoverFromRect:[sender bounds] inView:sender permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    }
    else {
        viewControllerToPresent.modalPresentationStyle = UIModalPresentationPopover;
        viewControllerToPresent.popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirectionAny;
        viewControllerToPresent.popoverPresentationController.backgroundColor = [UIColor appearancePopoverBackgroundColor];
        if ([sender isKindOfClass:[UIBarButtonItem class]])
            viewControllerToPresent.popoverPresentationController.barButtonItem = sender;
        else {
            viewControllerToPresent.popoverPresentationController.sourceView = sender;
            viewControllerToPresent.popoverPresentationController.sourceRect = [sender bounds];
        }
        [self presentViewController:viewControllerToPresent animated:YES completion:nil];
    }
}

@end
