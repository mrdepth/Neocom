//
//  UIAlertController+Neocom.h
//  Neocom
//
//  Created by Артем Шиманский on 21.10.15.
//  Copyright © 2015 Artem Shimanski. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIAlertController (Neocom)

+ (instancetype) alertWithTitle:(NSString *)title message:(NSString *)message;
+ (instancetype) alertWithError:(NSError *)error;
+ (UIViewController*) frontMostViewController;

@end
