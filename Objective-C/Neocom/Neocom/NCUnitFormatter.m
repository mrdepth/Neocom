//
//  NCUnitFormatter.m
//  Neocom
//
//  Created by Artem Shimanski on 15.11.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCUnitFormatter.h"

@implementation NCUnitFormatter

+ (NSString*) localizedStringFromNumber:(NSNumber*) number unit:(NCUnit) unit style:(NCUnitFormatterStyle) style {
	NSString* unitAbbreviation;
	double value = [number doubleValue];
	switch (unit) {
		case NCUnitISK:
			unitAbbreviation = NSLocalizedString(@"ISK", nil);
			break;
		case NCUnitSP:
			unitAbbreviation = NSLocalizedString(@"SP", nil);
			break;
		default:
			unitAbbreviation = nil;
			break;
	}
	NSString* suffix = nil;
	BOOL siPrefixed = (unit & NCUnitSIPrefixed) == 0;
	if (style == NCUnitFormatterStyleShort) {
		if (value >= 10000000000000) {
			suffix = NSLocalizedString(@"T", @"trillion");
			value /= 1000000000.0;
		}
		else if (value >= 10000000000) {
			if (siPrefixed)
				suffix = NSLocalizedString(@"G", @"billion");
			else
				suffix = NSLocalizedString(@"B", @"billion");
			value /= 1000000000.0;
		}
		else if (value >= 10000000) {
			suffix = NSLocalizedString(@"M", @"million");
			value /= 1000000.0;
		}
		else if (value >= 10000) {
			suffix = NSLocalizedString(@"k", @"thousand");
			value /= 1000.0;
		}
		else {
			suffix = nil;
		}
	}
	
	NSMutableString* s;
	if (value < 10.0) {
		static NSNumberFormatter* numberFormatter;
		static dispatch_once_t onceToken;
		dispatch_once(&onceToken, ^{
			numberFormatter = [NSNumberFormatter new];
			numberFormatter.positiveFormat = @"#,##0.##";
			numberFormatter.groupingSeparator = @" ";
			numberFormatter.decimalSeparator = @".";
		});
		s = [[numberFormatter stringFromNumber:@(value)] mutableCopy];
	}
	else {
		static NSNumberFormatter* numberFormatter;
		static dispatch_once_t onceToken;
		dispatch_once(&onceToken, ^{
			numberFormatter = [NSNumberFormatter new];
			numberFormatter.positiveFormat = @"#,##0";
			numberFormatter.groupingSeparator = @" ";
			numberFormatter.decimalSeparator = @".";
		});
		s = [[numberFormatter stringFromNumber:@(value)] mutableCopy];
	}
	if (suffix)
		[s appendString:suffix];
	if (unitAbbreviation)
		[s appendFormat:@" %@", unitAbbreviation];
	return s;
}

- (NSString*) stringForObjectValue:(id)obj {
	return [self.class localizedStringFromNumber:obj unit:self.unit style:self.style];
}

@end
