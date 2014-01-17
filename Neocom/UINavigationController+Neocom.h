//
//  UINavigationController+Neocom.h
//  Neocom
//
//  Created by Артем Шиманский on 17.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UINavigationController (Neocom)

- (void) updateScrollViewFromViewController:(UIViewController*) from toViewController:(UIViewController*) to;

@end
