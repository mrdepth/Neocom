//
//  NCSplitViewController.m
//  Neocom
//
//  Created by Artem Shimanski on 14.11.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCSplitViewController.h"

@interface NCSplitViewController ()

@end

@implementation NCSplitViewController

- (UIStatusBarStyle) preferredStatusBarStyle {
	return [self.viewControllers[0] preferredStatusBarStyle];
}
@end
