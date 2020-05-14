//
//  UIViewController+NC.h
//  Neocom
//
//  Created by Artem Shimanski on 18.11.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIViewController (NC)
@property (nonatomic, readonly) __kindof UIViewController* topmostViewController;
@end
