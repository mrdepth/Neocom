//
//  NSString+Neocom.m
//  Neocom
//
//  Created by Артем Шиманский on 10.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NSString+Neocom.h"

@implementation NSString (Neocom)

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

+ (NSString*) shortStringWithFloat:(float) value unit:(NSString*) unit {
	NSInteger dimension = [self dimensionForValue:value];
	return unit ?
		[NSString stringWithFormat:@"%.1f%@ %@", value / dimension, [self unitForDimension:dimension], unit] :
		[NSString stringWithFormat:@"%.1f%@", value / dimension, [self unitForDimension:dimension]];
}

+ (NSString*) stringWithTimeLeft:(NSTimeInterval) timeLeft {
	return [self stringWithTimeLeft:timeLeft componentsLimit:4];
}

+ (NSString*) stringWithTimeLeft:(NSTimeInterval) timeLeft componentsLimit:(NSInteger) componentsLimit {
	NSMutableString *text = [NSMutableString string];
	int sec = timeLeft;
	if (sec < 0)
		sec = 0;
	
	int days = sec / (60 * 60 * 24);
	sec %= (60 * 60 * 24);
	
	
	int hours = sec / (60 * 60);
	sec %= (60 * 60);
	
	int mins = sec / 60;
	sec %= 60;
	
	if (days && componentsLimit) {
		[text appendFormat:@"%dd ", days];
		componentsLimit--;
	}
	
	if (hours && componentsLimit) {
		[text appendFormat:@"%dh ", hours];
		componentsLimit--;
	}
	
	if (mins && componentsLimit) {
		[text appendFormat:@"%dm ", mins];
		componentsLimit--;
	}
	
	if ((sec || text.length == 0) && componentsLimit) {
		[text appendFormat:@"%ds", sec];
	}
	return text;
}


@end
