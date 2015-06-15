//
//  NCAdaptivePopoverSegue.m
//  Neocom
//
//  Created by Артем Шиманский on 15.06.15.
//  Copyright (c) 2015 Artem Shimanski. All rights reserved.
//

#import "NCAdaptivePopoverSegue.h"
#import "NCPopoverController.h"

@implementation NCAdaptivePopoverSegue

- (void) perform {
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		UINavigationController* controller = [[UINavigationController alloc] initWithRootViewController:self.destinationViewController];
		controller.navigationBar.barStyle = UIBarStyleBlack;
		controller.navigationBar.tintColor = [UIColor whiteColor];
		
		if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_7_1) {
			NCPopoverController* popoverController = [[NCPopoverController alloc] initWithContentViewController:self.destinationViewController];
			if ([self.sender isKindOfClass:[UIBarButtonItem class]])
				[popoverController presentPopoverFromBarButtonItem:self.sender permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
			else
				[popoverController presentPopoverFromRect:[self.sender bounds] inView:self.sender permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
		}
		else {
			controller.modalPresentationStyle = UIModalPresentationPopover;
			controller.popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirectionAny;
			controller.popoverPresentationController.backgroundColor = [UIColor blackColor];
			if ([self.sender isKindOfClass:[UIBarButtonItem class]])
				controller.popoverPresentationController.barButtonItem = self.sender;
			else {
				controller.popoverPresentationController.sourceView = self.sender;
				controller.popoverPresentationController.sourceRect = [self.sender bounds];
			}
			[self.sourceViewController presentViewController:controller animated:YES completion:nil];
		}
	}
	else {
		[[self.sourceViewController navigationController] pushViewController:self.destinationViewController animated:YES];
	}
}

@end
