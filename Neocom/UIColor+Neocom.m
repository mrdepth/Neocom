//
//  UIColor+Neocom.m
//  Neocom
//
//  Created by Артем Шиманский on 13.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "UIColor+Neocom.h"

@implementation UIColor (Neocom)

+ (instancetype) colorWithSecurity:(float) security {
	if (security >= 0.5f)
		return [UIColor greenColor];
	else if (security > 0.0f)
		return [UIColor orangeColor];
	else
		return [UIColor redColor];
}

@end
