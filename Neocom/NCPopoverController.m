//
//  NCPopoverController.m
//  Neocom
//
//  Created by Артем Шиманский on 15.06.15.
//  Copyright (c) 2015 Artem Shimanski. All rights reserved.
//

#import "NCPopoverController.h"
#import <objc/runtime.h>

@interface UIViewController()
@property (nonatomic, strong, readwrite) NCPopoverController* popover;
@end

@implementation NCPopoverController

- (id) initWithContentViewController:(UIViewController *)viewController {
	if (self = [super initWithContentViewController:viewController]) {
		viewController.popover = self;
		self.delegate = self;
	}
	return self;
}

- (void) dismissPopoverAnimated:(BOOL)animated {
	[super dismissPopoverAnimated:animated];
	self.contentViewController.popover = nil;
	objc_setAssociatedObject(self.contentViewController, @"popover", nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

#pragma mark - UIPopoverControllerDelegate

- (void) popoverControllerDidDismissPopover:(UIPopoverController *)popoverController {
	self.contentViewController.popover = nil;
}

@end
