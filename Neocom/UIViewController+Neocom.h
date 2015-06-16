//
//  UIViewController+Neocom.h
//  Neocom
//
//  Created by Shimanski Artem on 28.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIViewController (Neocom)

- (IBAction)dismissAnimated;

- (void) presentViewControllerInPopover:(UIViewController *)viewControllerToPresent withSender:(id) sender animated:(BOOL)animated;
@end
