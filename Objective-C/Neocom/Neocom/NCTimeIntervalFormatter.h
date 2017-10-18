//
//  NCTimeIntervalFormatter.h
//  Neocom
//
//  Created by Artem Shimanski on 15.11.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, NCTimeIntervalFormatterPrecision) {
	NCTimeIntervalFormatterPrecisionSeconds,
	NCTimeIntervalFormatterPrecisionMinuts,
	NCTimeIntervalFormatterPrecisionHours,
	NCTimeIntervalFormatterPrecisionDays
};

@interface NCTimeIntervalFormatter : NSFormatter
@property (nonatomic, assign) NCTimeIntervalFormatterPrecision precision;

+ (NSString*) localizedStringFromTimeInterval:(NSTimeInterval) time precision:(NCTimeIntervalFormatterPrecision) precision;
@end
