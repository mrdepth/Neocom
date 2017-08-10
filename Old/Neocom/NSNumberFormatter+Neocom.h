//
//  NSNumberFormatter+Neocom.h
//  Neocom
//
//  Created by Артем Шиманский on 10.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSNumberFormatter (Neocom)

+ (NSString *)neocomLocalizedStringFromInteger:(NSInteger)value;
+ (NSString *)neocomLocalizedStringFromNumber:(NSNumber*)value;

@end
