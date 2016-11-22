//
//  UIColor+NC.m
//  Neocom
//
//  Created by Artem Shimanski on 22.11.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "UIColor+NC.h"
#import "UIColor+CS.h"

@implementation UIColor (NC)

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

@end
