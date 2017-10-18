//
//  UIImage+Neocom.m
//  Neocom
//
//  Created by Артем Шиманский on 31.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "UIImage+Neocom.h"

@implementation UIImage (Neocom)

+ (instancetype) emptyImage {
	static UIImage* emptyImage = nil;
	if (!emptyImage) {
		UIGraphicsBeginImageContextWithOptions(CGSizeMake(1, 1), NO, 1);
		CGContextClearRect(UIGraphicsGetCurrentContext(), CGRectMake(0, 0, 1, 1));
		
		emptyImage = UIGraphicsGetImageFromCurrentImageContext();
		UIGraphicsEndImageContext();
	}
	return emptyImage;
}

+ (instancetype) emptyImageWithSize:(CGSize) size {
	UIGraphicsBeginImageContextWithOptions(size, NO, [[UIScreen mainScreen] scale]);
	CGContextClearRect(UIGraphicsGetCurrentContext(), (CGRect){.origin = CGPointZero, .size = size});
	
	UIImage* image = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	return image;
}

@end
