//
//  UIColor+NC.h
//  Neocom
//
//  Created by Artem Shimanski on 15.11.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIColor (NC)

+ (instancetype) colorWithString:(NSString*) string;
+ (instancetype) colorWithUInteger:(NSUInteger) value;
+ (instancetype) backgroundColor;

@end
