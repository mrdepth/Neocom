//
//  UIColor+Neocom.h
//  Neocom
//
//  Created by Артем Шиманский on 13.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIColor (Neocom)

+ (instancetype) colorWithSecurity:(float) security;
+ (instancetype) colorWithPlayerSecurityStatus:(float) securityStatus;

+ (instancetype) appearanceTableViewBackgroundColor;
+ (instancetype) appearanceTableViewHeaderViewBackgroundColor;
+ (instancetype) appearanceTableViewCellBackgroundColor;
+ (instancetype) appearanceTableViewSeparatorColor;
+ (instancetype) appearancePopoverBackgroundColor;

+ (instancetype) urlColor;

@end
