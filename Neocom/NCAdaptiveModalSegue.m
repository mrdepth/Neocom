//
//  NCAdaptiveModalSegue.m
//  Neocom
//
//  Created by Артем Шиманский on 10.06.15.
//  Copyright (c) 2015 Artem Shimanski. All rights reserved.
//

#import "NCAdaptiveModalSegue.h"
#import "UIViewController+Neocom.h"

@implementation NCAdaptiveModalSegue

- (void) perform {
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		UINavigationController* controller = [[UINavigationController alloc] initWithRootViewController:self.destinationViewController];
		controller.navigationBar.barStyle = UIBarStyleBlack;
		controller.navigationBar.tintColor = [UIColor whiteColor];
		controller.modalPresentationStyle = UIModalPresentationFormSheet;
		[[self.destinationViewController navigationItem] setLeftBarButtonItem:[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Close", nil) style:UIBarButtonItemStylePlain target:self.destinationViewController action:@selector(dismissAnimated)]];
		[self.sourceViewController presentViewController:controller animated:YES completion:nil];
	}
	else {
		[[self.sourceViewController navigationController] pushViewController:self.destinationViewController animated:YES];
	}
}

@end
