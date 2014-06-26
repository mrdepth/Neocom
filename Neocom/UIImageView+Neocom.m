//
//  UIImageView+Neocom.m
//  Neocom
//
//  Created by Shimanski Artem on 19.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "UIImageView+Neocom.h"
#import <ImageIO/ImageIO.h>

@implementation UIImageView (Neocom)

- (void) setGIFImageWithContentsOfURL:(NSURL*) url {
	self.image = nil;
	
	CGImageSourceRef source = CGImageSourceCreateWithURL((__bridge CFURLRef) url, NULL);
	if (!source)
		return;
	
	size_t n = CGImageSourceGetCount(source);
	if (n == 0) {
		CFRelease(source);
		return;
	}
	
	NSMutableArray *images = [NSMutableArray array];
	for (int i = 0; i < n; i++) {
		CGImageRef img = CGImageSourceCreateImageAtIndex(source, i, NULL);
		[images addObject:[UIImage imageWithCGImage:img]];
		CGImageRelease(img);
	}
	self.image = [images objectAtIndex:0];
	self.animationImages = images;
	
	CFRelease(source);
	
	self.animationDuration = 1.5;
	[self startAnimating];
}

@end
