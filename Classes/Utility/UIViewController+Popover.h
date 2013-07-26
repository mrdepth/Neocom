//
//  UIViewController+Popover.h
//  EVEUniverse
//
//  Created by mr_depth on 22.07.13.
//
//

#import <UIKit/UIKit.h>

@interface UIViewController (Popover)

- (void)presentViewControllerInPopover:(UIViewController *)viewControllerToPresent fromBarButtonItem:(UIBarButtonItem *)item permittedArrowDirections:(UIPopoverArrowDirection)arrowDirections animated:(BOOL)animated;
- (void)presentViewControllerInPopover:(UIViewController *)viewControllerToPresent fromRect:(CGRect) rect inView:(UIView*) view permittedArrowDirections:(UIPopoverArrowDirection)arrowDirections animated:(BOOL)animated;

@end
