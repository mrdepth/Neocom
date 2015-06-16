//
//  NCPopoverController.m
//  Neocom
//
//  Created by Артем Шиманский on 15.06.15.
//  Copyright (c) 2015 Artem Shimanski. All rights reserved.
//

#import "NCPopoverController.h"
#import <objc/runtime.h>

@implementation NCPopoverController

- (id) initWithContentViewController:(UIViewController *)viewController {
	if (self = [super initWithContentViewController:viewController]) {
		objc_setAssociatedObject(viewController, @"popover", self, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
		self.delegate = self;
	}
	return self;
}

- (void) dismissPopoverAnimated:(BOOL)animated {
	[super dismissPopoverAnimated:animated];
	objc_setAssociatedObject(self.contentViewController, @"popover", nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

#pragma mark - UIPopoverControllerDelegate

- (void) popoverControllerDidDismissPopover:(UIPopoverController *)popoverController {
	objc_setAssociatedObject(self.contentViewController, @"popover", nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
