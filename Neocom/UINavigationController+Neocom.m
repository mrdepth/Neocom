//
//  UINavigationController+Neocom.m
//  Neocom
//
//  Created by Артем Шиманский on 17.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "UINavigationController+Neocom.h"

@interface UINavigationController()
- (void) _updateScrollViewFromViewController:(UIViewController*) from toViewController:(UIViewController*) to;
@end

@implementation UINavigationController (Neocom)

- (void) updateScrollViewFromViewController:(UIViewController*) from toViewController:(UIViewController*) to {
	if ([UINavigationController instancesRespondToSelector:@selector(_updateScrollViewFromViewController:toViewController:)])
		[self _updateScrollViewFromViewController:from toViewController:to];
}

@end
