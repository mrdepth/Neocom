//
//  NSString+NC.m
//  Neocom
//
//  Created by Artem Shimanski on 25.11.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NSString+NC.h"

@implementation NSString (NC)

+ (NSString*) stringWithRomanNumber:(NSUInteger) romanNumber {
	NSParameterAssert(romanNumber >= 0 && romanNumber <= 5);
	static const char* roman[]={"0","I","II","III","IV","V"};
	return @(roman[romanNumber]);
}

@end
