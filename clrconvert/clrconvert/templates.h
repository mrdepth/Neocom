//
//  templates.h
//  clrconvert
//
//  Created by Artem Shimanski on 17.11.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//



#ifndef templates_h
#define templates_h

NSString* sourceMethodTemplate = @R"(
+ (instancetype) %@ {
	static UIColor* color = nil;
	if (!color)
		color = [UIColor colorWithUInteger:0x%@];
	return color;
}
)";


/////////////////////


NSString* headerMethodTemplate = @R"(
+ (instancetype) %@;
)";


/////////////////////


NSString* headerTemplate = @R"(
//
//  UIColor+%1$@.h
//
//  Created by Artem Shimanski
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIColor (%1$@)

+ (instancetype) colorWithUInteger:(NSUInteger) value;
%2$@
@end
)";


/////////////////////


NSString* sourceTemplate = @R"(
//
//  UIColor+%1$@.m
//
//  Created by Artem Shimanski
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "UIColor+%1$@.h"

@implementation UIColor (%1$@)

+ (instancetype) colorWithUInteger:(NSUInteger) value {
	const Byte* abgr = (const Byte*) &value;
	return [UIColor colorWithRed:abgr[3] / 255.0 green:abgr[2] / 255.0 blue:abgr[1] / 255.0 alpha:abgr[0] / 255.0];
}

%2$@
@end
)";


#endif /* templates_h */
