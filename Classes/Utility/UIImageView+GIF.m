//
//  UIImageView+GIF.m
//  EVEUniverse
//
//  Created by Artem Shimanski on 1/26/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "UIImageView+GIF.h"


@implementation UIImageView(GIF)

- (void) setGIFImageWithContentsOfURL:(NSURL*) url {
	self.image = nil;
	
	CGImageSourceRef source = CGImageSourceCreateWithURL((CFURLRef) url, NULL);
	if (!source)
		return;
	
	int n = CGImageSourceGetCount(source);
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
