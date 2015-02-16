//
//  NSString+Neocom.m
//  Neocom
//
//  Created by Артем Шиманский on 10.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NSString+Neocom.h"
#import "NSNumberFormatter+Neocom.h"

@implementation NSString (Neocom)

+ (NSInteger) dimensionForValue:(float) value {
	if (isinf(value))
		return 1;
	value = fabs(value);
	if (value >= 10000000)
		return 1000000;
	else if (value >= 10000)
		return 1000;
	else
		return 1;
}

+ (NSString*) dimensionSuffix:(NSInteger) dimension {
	if (dimension == 1000000)
		return @"M";
	else if (dimension == 1000)
		return @"k";
	else
		return @"";
}

+ (NSString*) stringWithTotalResources:(float) total usedResources:(float) used unit:(NSString*) unit {
	NSInteger dimension = [self dimensionForValue:total];
	used /= dimension;
	total /= dimension;
	NSString* dimensionSuffix = [self dimensionSuffix:dimension];
	return [NSString stringWithFormat:@"%@%@/%@%@ %@",
			[NSNumberFormatter neocomLocalizedStringFromNumber:@(used)],
			dimensionSuffix,
			[NSNumberFormatter neocomLocalizedStringFromNumber:@(total)],
			dimensionSuffix,
			unit ? unit : @""];
}

+ (NSString*) shortStringWithFloat:(float) value unit:(NSString*) unit {
	if (isinf(value))
		return unit ?
		[NSString stringWithFormat:@"%f %@", value, unit] :
		[NSString stringWithFormat:@"%f", value];

	NSInteger dimension = [self dimensionForValue:value];
	value /= dimension;
	return unit ?
		[NSString stringWithFormat:@"%@%@ %@", [NSNumberFormatter neocomLocalizedStringFromNumber:@(value)], [self dimensionSuffix:dimension], unit] :
		[NSString stringWithFormat:@"%@%@", [NSNumberFormatter neocomLocalizedStringFromNumber:@(value)], [self dimensionSuffix:dimension]];
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

	BOOL space = NO;
	if (days && componentsLimit) {
		space = YES;
		[text appendFormat:@"%dd", days];
		componentsLimit--;
	}
	
	if (hours && componentsLimit) {
		if (space)
			[text appendString:@" "];
		space = YES;

		[text appendFormat:@"%dh", hours];
		componentsLimit--;
	}
	
	if (mins && componentsLimit) {
		if (space)
			[text appendString:@" "];
		space = YES;

		[text appendFormat:@"%dm", mins];
		componentsLimit--;
	}

	if ((sec || text.length == 0) && componentsLimit) {
		if (space)
			[text appendString:@" "];
		[text appendFormat:@"%ds", sec];
	}
	return text;
}


@end
