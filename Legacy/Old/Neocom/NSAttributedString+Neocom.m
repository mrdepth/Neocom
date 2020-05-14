//
//  NSAttributedString+Neocom.m
//  Neocom
//
//  Created by Artem Shimanski on 14.02.15.
//  Copyright (c) 2015 Artem Shimanski. All rights reserved.
//

#import "NSAttributedString+Neocom.h"
#import "NSNumberFormatter+Neocom.h"
#import "UIColor+Neocom.h"

@implementation NSAttributedString (Neocom)

+ (NSAttributedString*) attributedStringWithTotalResources:(float) total usedResources:(float) used unit:(NSString*) unit {
	NSInteger dimension = [self dimensionForValue:total];
	used /= dimension;
	total /= dimension;
	NSString* dimensionSuffix = [self dimensionSuffix:dimension];
	NSMutableAttributedString* s = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@%@/%@%@",
																					  [NSNumberFormatter neocomLocalizedStringFromNumber:@(used)],
																					  dimensionSuffix,
																					  [NSNumberFormatter neocomLocalizedStringFromNumber:@(total)],
																					  dimensionSuffix]
																		  attributes:@{NSForegroundColorAttributeName: [UIColor whiteColor]}];
	if (unit)
		[s appendAttributedString:[[NSAttributedString alloc] initWithString:[@" " stringByAppendingString:unit] attributes:nil]];
	return s;
}

+ (NSAttributedString*) shortAttributedStringWithFloat:(float) value unit:(NSString*) unit {
	if (isinf(value)) {
		NSMutableAttributedString* s = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%f", value]
																			  attributes:@{NSForegroundColorAttributeName: [UIColor whiteColor]}];
		if (unit)
			[s appendAttributedString:[[NSAttributedString alloc] initWithString:[@" " stringByAppendingString:unit] attributes:nil]];
		return s;
	}
	else {
		NSInteger dimension = [self dimensionForValue:value];
		value /= dimension;
		
		NSMutableAttributedString* s = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@%@", [NSNumberFormatter neocomLocalizedStringFromNumber:@(value)], [self dimensionSuffix:dimension]]
																			  attributes:@{NSForegroundColorAttributeName: [UIColor whiteColor]}];
		if (unit)
			[s appendAttributedString:[[NSAttributedString alloc] initWithString:[@" " stringByAppendingString:unit] attributes:nil]];
		return s;
	}
}

+ (NSAttributedString*) attributedStringWithTimeLeft:(NSTimeInterval) timeLeft {
	return [self attributedStringWithTimeLeft:timeLeft componentsLimit:4];
}

+ (NSAttributedString*) attributedStringWithTimeLeft:(NSTimeInterval) timeLeft componentsLimit:(NSInteger) componentsLimit {
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
	return [[NSAttributedString alloc] initWithString:text attributes:@{NSForegroundColorAttributeName:[UIColor whiteColor]}];
}

+ (NSAttributedString*) attributedStringWithString:(NSString*) string url:(NSURL*) url {
	if (!string)
		return nil;
	return [[NSAttributedString alloc] initWithString:string
										   attributes:@{@"NSURL":url}];
}

+ (NSAttributedString*) attributedStringWithHTMLString:(NSString*) html {
	if (!html)
		return nil;
	
	NSMutableAttributedString* s = [[NSMutableAttributedString alloc] initWithString:html attributes:nil];
	
	NSRegularExpression* expression = [NSRegularExpression regularExpressionWithPattern:@"<(color|font)[^>]*=[\"']?(.*?)[\"']?\\s*?>(.*?)</(color|font)>"
																				options:NSRegularExpressionCaseInsensitive
																				  error:nil];
	NSTextCheckingResult* result;
	
	while ((result = [expression firstMatchInString:s.string options:0 range:NSMakeRange(0, s.length)]) != nil) {
		NSString* colorString = [s.string substringWithRange:[result rangeAtIndex:2]];
		UIColor* color = [UIColor colorWithString:colorString];
		
		NSMutableAttributedString* replace = [[s attributedSubstringFromRange:[result rangeAtIndex:3]] mutableCopy];
		if (color)
			[replace addAttribute:NSForegroundColorAttributeName value:color range:NSMakeRange(0, replace.length)];
		[s replaceCharactersInRange:[result rangeAtIndex:0] withAttributedString:replace];
	}
	return s;
}

#pragma mark - Private

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

@end
