//
//  NCMenuViewController.h
//  Neocom
//
//  Created by Admin on 08.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NCMenuViewController : UIViewController
@property (nonatomic, strong) IBOutlet UIViewController* menuViewController;
@property (nonatomic, strong) IBOutlet UIViewController* contentViewController;
@property (nonatomic, assign, getter = isMenuVisible) BOOL menuVisible;

- (void) setContentViewController:(UIViewController *)contentViewController animated:(BOOL)animated;
- (void) setMenuVisible:(BOOL)menuVisible animated:(BOOL)animated;
@end
