//
//  NCUnitFormatter.h
//  Neocom
//
//  Created by Artem Shimanski on 15.11.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, NCUnitFormatterStyle) {
	NCUnitFormatterStyleShort,
	NCUnitFormatterStyleFull
};

typedef NS_ENUM(NSInteger, NCUnit) {
	NCUnitSIPrefixed = 0x1000,
	NCUnitNone = 0x0,
	NCUnitISK = 0x1,
	NCUnitSP = 0x2,
};


@interface NCUnitFormatter : NSFormatter
@property (nonatomic, assign) NCUnitFormatterStyle style;
@property (nonatomic, assign) NCUnit unit;

+ (NSString*) localizedStringFromNumber:(NSNumber*) number unit:(NCUnit) unit style:(NCUnitFormatterStyle) style;


@end
