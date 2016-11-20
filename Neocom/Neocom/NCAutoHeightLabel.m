//
//  NCAutoHeightLabel.m
//  Neocom
//
//  Created by Artem Shimanski on 19.11.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCAutoHeightLabel.h"

@implementation NCAutoHeightLabel

- (void) drawRect:(CGRect)rect {
	NSMutableAttributedString* as = [self.attributedText mutableCopy];
	NSStringDrawingContext* context = [[NSStringDrawingContext alloc] init];
	CGRect bounds = [as boundingRectWithSize:CGSizeMake(FLT_MAX, FLT_MAX) options:NSStringDrawingUsesLineFragmentOrigin context:context];
	CGFloat scale = MIN(rect.size.width / bounds.size.width, rect.size.height / bounds.size.height);
	scale = MIN(scale, 1.0);
	CGContextRef cgContext = UIGraphicsGetCurrentContext();
	CGContextTranslateCTM(cgContext, CGRectGetMidX(rect), CGRectGetMidY(rect));
	CGContextScaleCTM(cgContext, scale, scale);
	CGContextTranslateCTM(cgContext, -CGRectGetMidX(bounds), -CGRectGetMidY(bounds));
	[as drawWithRect:bounds options:NSStringDrawingUsesLineFragmentOrigin context:nil];
}

@end
