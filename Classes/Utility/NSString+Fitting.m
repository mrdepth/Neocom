//
//  NSString+Fitting.m
//  EVEUniverse
//
//  Created by Artem Shimanski on 5/10/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "NSString+Fitting.h"


@implementation NSString(Fitting)

+ (NSInteger) dimensionForValue:(float) value {
	if (value >= 10000000)
		return 1000000;
	else if (value >= 10000)
		return 1000;
	else
		return 1;
}

+ (NSString*) unitForDimension:(NSInteger) dimension {
	if (dimension == 1000000)
		return @"M";
	else if (dimension == 1000)
		return @"k";
	else
		return @"";
}

+ (NSString*) stringWithTotalResources:(float) total usedResources:(float) used unit:(NSString*) unit {
	NSInteger dimension = [self dimensionForValue:total];
	return [NSString stringWithFormat:@"%.1f/%.1f%@ %@", used / dimension, total / dimension, [self unitForDimension:dimension], unit ? unit : @""];
}

+ (NSString*) stringWithResource:(float) resource unit:(NSString*) unit {
	NSInteger dimension = [self dimensionForValue:resource];
	return [NSString stringWithFormat:@"%.1f%@ %@", resource / dimension, [self unitForDimension:dimension], unit ? unit : @""];
}

@end
