//
//  UIViewController+NC.m
//  Neocom
//
//  Created by Artem Shimanski on 18.11.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "UIViewController+NC.h"

@implementation UIViewController (NC)

- (__kindof UIViewController*) topmostViewController {
	UIViewController* controller;
	for (controller = self; controller.presentedViewController; controller = controller.presentedViewController);
	return controller;
}

@end
