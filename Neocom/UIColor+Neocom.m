//
//  UIColor+Neocom.m
//  Neocom
//
//  Created by Артем Шиманский on 13.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "UIColor+Neocom.h"
#import "UIColor+NSNumber.h"

@implementation UIColor (Neocom)

+ (instancetype) colorWithSecurity:(float) security {
	if (security >= 1.0f)
		return [UIColor colorWithUInteger:0x2FEFEFFF];
	else if (security >= 0.9f)
		return [UIColor colorWithUInteger:0x48F0C0FF];
	else if (security >= 0.8f)
		return [UIColor colorWithUInteger:0x00EF47FF];
	else if (security >= 0.7f)
		return [UIColor colorWithUInteger:0x00F000FF];
	else if (security >= 0.6f)
		return [UIColor colorWithUInteger:0x8FEF2FFF];
	else if (security >= 0.5f)
		return [UIColor colorWithUInteger:0xEFEF00FF];
	else if (security >= 0.4f)
		return [UIColor colorWithUInteger:0xD77700FF];
	else if (security >= 0.3f)
		return [UIColor colorWithUInteger:0xF06000FF];
	else if (security >= 0.2f)
		return [UIColor colorWithUInteger:0xF04800FF];
	else if (security >= 0.1f)
		return [UIColor colorWithUInteger:0xD73000FF];
	else
		return [UIColor colorWithUInteger:0xF00000FF];
}

+ (instancetype) colorWithPlayerSecurityStatus:(float) securityStatus {
	if (securityStatus > -2.0f)
		return [self colorWithSecurity:0.5 + (securityStatus + 2.0f) / 14.0f];
	else
		return [self colorWithSecurity:(securityStatus + 5.0f - FLT_EPSILON) / 6.0f];
}

+ (instancetype) appearanceTableViewBackgroundColor {
	return [UIColor colorWithUInteger:0x1f1e23ff];
}

+ (instancetype) appearanceTableViewHeaderViewBackgroundColor {
	//return [self appearanceTableViewBackgroundColor];
	return [UIColor colorWithUInteger:0x1f1e23F0];
}

+ (instancetype) appearanceTableViewCellBackgroundColor {
	return [self appearanceTableViewBackgroundColor];
}

+ (instancetype) appearanceTableViewSeparatorColor {
	return [UIColor colorWithUInteger:0x5b5866ff];
}


+ (instancetype) appearancePopoverBackgroundColor {
	return [self appearanceTableViewBackgroundColor];
}

+ (instancetype) urlColor {
	return [UIColor colorWithUInteger:0xffa500ff];
}

+ (instancetype) colorWithString:(NSString*) string {
	unsigned int rgba;
	if ([[NSScanner scannerWithString:string] scanHexInt:&rgba]) {
		return [self colorWithUInteger:rgba];
	}
	else {
		static NSDictionary* map = nil;
		if (!map) {
			static dispatch_once_t onceToken;
			dispatch_once(&onceToken, ^{
				NSMutableDictionary* dic = [NSMutableDictionary new];
				dic[@"black"] = [UIColor blackColor];
				dic[@"darkgray"] = [UIColor darkGrayColor];
				dic[@"lightgray"] = [UIColor lightGrayColor];
				dic[@"white"] = [UIColor whiteColor];
				dic[@"gray"] = [UIColor grayColor];
				dic[@"red"] = [UIColor redColor];
				dic[@"green"] = [UIColor greenColor];
				dic[@"blue"] = [UIColor blueColor];
				dic[@"cyan"] = [UIColor cyanColor];
				dic[@"yellow"] = [UIColor yellowColor];
				dic[@"magenta"] = [UIColor magentaColor];
				dic[@"orange"] = [UIColor orangeColor];
				dic[@"purple"] = [UIColor purpleColor];
				dic[@"brown"] = [UIColor brownColor];
				map = dic;
			});
		}
		NSString* key = [string lowercaseString];
		return map[key] ?: [UIColor clearColor];
	}
}

@end
