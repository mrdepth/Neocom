//
//  EVECharacterSheet+NC.m
//  Neocom
//
//  Created by Artem Shimanski on 22.11.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "EVECharacterSheet+NC.h"

@implementation EVECharacterSheet (NC)

- (NSDate*) nextRespecDate {
	NSCalendar* calendar = [NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian];
	NSCalendarUnit unitFlags = NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond | NSCalendarUnitTimeZone;
	NSDateComponents* components = [calendar components:unitFlags fromDate:self.lastRespecDate];
	components.year++;
	return [calendar dateFromComponents:components];
}

@end
