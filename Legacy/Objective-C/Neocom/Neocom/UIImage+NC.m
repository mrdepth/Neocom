//
//  UIImage+NC.m
//  Neocom
//
//  Created by Artem Shimanski on 20.11.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "UIImage+NC.h"
#import "UIColor+CS.h"

@implementation UIImage (NC)

+ (instancetype) imageWithColor:(UIColor*) color {
	UIGraphicsBeginImageContextWithOptions(CGSizeMake(1, 1), NO, 1);
	[color setFill];
	[[UIBezierPath bezierPathWithRect:CGRectMake(0, 0, 1, 1)] fill];
	UIImage* image = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	return [image resizableImageWithCapInsets:UIEdgeInsetsZero resizingMode:UIImageResizingModeTile];
}

+ (instancetype) searchFieldBackgroundImageWithColor:(UIColor*) color {
	UIGraphicsBeginImageContextWithOptions(CGSizeMake(28, 28), NO, [[UIScreen mainScreen] scale]);
	[color setFill];
	UIBezierPath* path = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, 28, 28) cornerRadius:5];
	[path fill];
	UIImage* image = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	return [image resizableImageWithCapInsets:UIEdgeInsetsMake(5, 5, 5, 5) resizingMode:UIImageResizingModeStretch];
}

@end
