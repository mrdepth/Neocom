//
//  NCAdaptivePopoverSegue.m
//  Neocom
//
//  Created by Артем Шиманский on 15.06.15.
//  Copyright (c) 2015 Artem Shimanski. All rights reserved.
//

#import "NCAdaptivePopoverSegue.h"
#import "NCPopoverController.h"
#import "UIViewController+Neocom.h"
#import "NCNavigationController.h"

@implementation NCAdaptivePopoverSegue

- (void) perform {
	id sender = [self.sender isKindOfClass:[NSDictionary class]] ? self.sender[@"sender"] : self.sender;
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		NCNavigationController* controller = [[NCNavigationController alloc] initWithRootViewController:self.destinationViewController];
		controller.navigationBar.barStyle = UIBarStyleBlack;
		controller.navigationBar.tintColor = [UIColor whiteColor];
		//controller.preferredContentSize = CGSizeMake(320, 768);
        [self.sourceViewController presentViewControllerInPopover:controller withSender:sender animated:YES];
	}
	else {
		[self.sourceViewController showViewController:self.destinationViewController sender:sender];
		//[[self.sourceViewController navigationController] pushViewController:self.destinationViewController animated:YES];
	}
}

@end
