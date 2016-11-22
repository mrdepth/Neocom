//
//  NCTimeIntervalFormatter.m
//  Neocom
//
//  Created by Artem Shimanski on 15.11.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCTimeIntervalFormatter.h"

@implementation NCTimeIntervalFormatter

+ (NSString*) localizedStringFromTimeInterval:(NSTimeInterval) time precision:(NCTimeIntervalFormatterPrecision) precision {
	unsigned int t = (unsigned int) time;
	unsigned int d = t / (60 * 60 * 24);
	unsigned int h = (t / (60 * 60)) % 24;
	unsigned int m = (t / 60) % 60;
	unsigned int s = t % 60;
	
	NSMutableString* string = [NSMutableString new];
	if (precision <= NCTimeIntervalFormatterPrecisionDays && d > 0)
		[string appendFormat:NSLocalizedString(@"%ud", nil), d];
	if (precision <= NCTimeIntervalFormatterPrecisionHours && h > 0)
		[string appendFormat:NSLocalizedString(@"%s%uh", nil), string.length > 0 ? " " : "", h];
	if (precision <= NCTimeIntervalFormatterPrecisionMinuts && m > 0)
		[string appendFormat:NSLocalizedString(@"%s%um", nil), string.length > 0 ? " " : "", m];
	if (precision <= NCTimeIntervalFormatterPrecisionSeconds && s > 0)
		[string appendFormat:NSLocalizedString(@"%s%us", nil), string.length > 0 ? " " : "", s];
	return string;

}

- (NSString*) stringForObjectValue:(id)obj {
	return [self.class localizedStringFromTimeInterval:[obj doubleValue] precision:self.precision];
}

@end
