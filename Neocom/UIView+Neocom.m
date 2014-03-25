//
//  UIView+Neocom.m
//  Neocom
//
//  Created by Артем Шиманский on 25.03.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "UIView+Neocom.h"

@implementation UIView (Neocom)

- (UIView*) snapshot {
	if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_6_1) {
		UIGraphicsBeginImageContextWithOptions(self.bounds.size, YES, self.contentScaleFactor);
		[self.layer drawInContext:UIGraphicsGetCurrentContext()];
		UIImage* image = UIGraphicsGetImageFromCurrentImageContext();
		UIGraphicsEndImageContext();
		return [[UIImageView alloc] initWithImage:image];
	}
	else {
		return [self snapshotViewAfterScreenUpdates:YES];
	}
}


@end
