//
//  NCSideMenuViewController.h
//  Neocom
//
//  Created by Admin on 08.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import <UIKit/UIKit.h>

#define NCSideMenuViewControllerAnimationDuration 0.35
#define NCSideMenuViewControllermMenuEdgeInset 40.0
#define NCSideMenuViewControllermPanWidth 30.0

@class NCSideMenuViewController;
@interface UIViewController(NCSideMenuViewController)
@property (nonatomic, weak, readonly) NCSideMenuViewController* sideMenuViewController;

@end

@interface NCSideMenuViewController : UIViewController
@property (nonatomic, strong) IBOutlet UIViewController* menuViewController;
@property (nonatomic, strong) IBOutlet UIViewController* contentViewController;
@property (nonatomic, assign, getter = isMenuVisible) BOOL menuVisible;
@property (nonatomic, assign, getter = isFullScreen) BOOL fullScreen;

- (void) setContentViewController:(UIViewController *)contentViewController animated:(BOOL)animated;
- (void) setMenuVisible:(BOOL)menuVisible animated:(BOOL)animated;
- (void) setFullScreen:(BOOL)fullScreen animated:(BOOL)animated;
- (IBAction)onMenu:(id)sender;
@end
