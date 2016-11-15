//
//  UIColor+NC.m
//  Neocom
//
//  Created by Artem Shimanski on 15.11.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "UIColor+NC.h"

@implementation UIColor (NC)

+ (instancetype) colorWithString:(NSString*) string {
	float rgba[] = {0,0,0,1};
	
	NSRange range = NSMakeRange(0, string.length);
	if ([string characterAtIndex:0] == '#') {
		range.length--;
		range.location++;
	}
	int i = 0;
	while (range.length > 0) {
		NSUInteger len = MIN(2, range.length);
		NSScanner* scanner = [NSScanner scannerWithString:[string substringWithRange:NSMakeRange(range.location, len)]];
		range.location += len;
		range.length -= len;
		unsigned int n = 0;
		if ([scanner scanHexInt:&n])
			rgba[i++] = n / 255.0;
		else
			return nil;
	}
	return [UIColor colorWithRed:rgba[0] green:rgba[1] blue:rgba[2] alpha:rgba[3]];
}

+ (instancetype) colorWithUInteger:(NSUInteger) value {
	const Byte* abgr = (const Byte*) &value;
	return [UIColor colorWithRed:abgr[3] / 255.0 green:abgr[2] / 255.0 blue:abgr[1] / 255.0 alpha:abgr[0] / 255.0];
}

+ (instancetype) backgroundColor {
	return [UIColor colorWithUInteger:0x172126FF];
}


@end
