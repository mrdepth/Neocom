//
//  NSDate+Neocom.m
//  Neocom
//
//  Created by Shimanski Artem on 25.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NSDate+Neocom.h"
#import "NSDate+DaysAgo.h"

@implementation NSDate (Neocom)

- (NSString*) messageTimeLocalizedString {
	NSInteger days = [self daysAgo];
	if (days == 0) {
		NSDateFormatter* dateFormatter = [NSDateFormatter new];
		[dateFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_GB"]];
		[dateFormatter setDateFormat:@"HH:mm"];
		return [dateFormatter stringFromDate:self];
	}
	else if (days == 1)
		return NSLocalizedString(@"Yesterday", nil);
	else {
		NSDateFormatter* dateFormatter = [NSDateFormatter new];
		[dateFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_GB"]];
		[dateFormatter setDateFormat:@"yyyy.MM.dd"];
		return [dateFormatter stringFromDate:self];
	}
}

@end
