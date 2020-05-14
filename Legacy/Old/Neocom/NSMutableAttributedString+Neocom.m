//
//  NSMutableAttributedString+Neocom.m
//  Neocom
//
//  Created by Artem Shimanski on 15.02.15.
//  Copyright (c) 2015 Artem Shimanski. All rights reserved.
//

#import "NSMutableAttributedString+Neocom.h"

@implementation NSMutableAttributedString (Neocom)

- (void) addAttributeForNumbers:(NSString *)name value:(id)value {
	NSRegularExpression* expression = [NSRegularExpression regularExpressionWithPattern:@"[+–-]?\\d+\\.?\\d*\%?[Mk]" options:0 error:nil];
	[expression enumerateMatchesInString:self.string
								 options:0
								   range:NSMakeRange(0, self.length)
							  usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
								  [self addAttribute:name value:value range:result.range];
							  }];
}

@end
