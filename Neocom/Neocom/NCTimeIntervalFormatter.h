//
//  NCTimeIntervalFormatter.h
//  Neocom
//
//  Created by Artem Shimanski on 15.11.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, NCTimeIntervalFormatterStyle) {
	NCTimeIntervalFormatterStyleSeconds,
	NCTimeIntervalFormatterStyleMinuts,
	NCTimeIntervalFormatterStyleHours,
	NCTimeIntervalFormatterStyleDays
};

@interface NCTimeIntervalFormatter : NSFormatter
@property (nonatomic, assign) NCTimeIntervalFormatterStyle style;

+ (NSString*) localizedStringFromTimeInterval:(NSTimeInterval) time style:(NCTimeIntervalFormatterStyle) style;
@end
