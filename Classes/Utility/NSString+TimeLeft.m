//
//  NSString+TimeLeft.m
//  EVEUniverse
//
//  Created by Artem Shimanski on 5/11/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "NSString+TimeLeft.h"


@implementation NSString(TimeLeft)

+ (NSString*) stringWithTimeLeft:(NSTimeInterval) timeLeft {
/*	NSMutableString *text = [NSMutableString string];
	int sec = timeLeft;
	if (sec < 0)
		sec = 0;
	
	int days = sec / (60 * 60 * 24);
	sec %= (60 * 60 * 24);
	
	
	int hours = sec / (60 * 60);
	sec %= (60 * 60);
	
	int mins = sec / 60;
	sec %= 60;
	
	if (days)
		[text appendFormat:@"%dd ", days];
	if (hours)
		[text appendFormat:@"%dh ", hours];
	if (mins)
		[text appendFormat:@"%dm ", mins];
	[text appendFormat:@"%ds", sec];
	return text;*/
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
