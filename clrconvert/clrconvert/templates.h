//
//  templates.h
//  clrconvert
//
//  Created by Artem Shimanski on 17.11.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//



#ifndef templates_h
#define templates_h

NSString* CSSchemeNameTemplate = @R"(
typedef NS_ENUM(NSInteger, CSSchemeName) {
%@
};)";

NSString* CSColorNameTemplate = @R"(
typedef NS_ENUM(NSInteger, CSColorName) {
%@
};)";

NSString* g_colorsTemplate = @R"(
static const NSUInteger colors[] = {%2$@};
const void* const %1$@ = colors;
)";

NSString* methodImplementationTemplate = @R"(
+ (instancetype) %@ {
	return [self colorWithUInteger:g_currentScheme[%@]];
}
)";

NSString* methodDeclarationTemplate = @R"(
+ (instancetype) %@;
)";

/////////////////////


NSString* headerTemplate = @R"(
//
//  UIColor+CS.h
//
//  Created by Artem Shimanski
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIColor (CS)
@property (nonatomic, class) const void* currentScheme;

+ (instancetype) colorWithUInteger:(NSUInteger) value;
%@
@end
)";


/////////////////////


NSString* implementationTemplate = @R"(
//
//  UIColor+CS.m
//
//  Created by Artem Shimanski
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "UIColor+CS.h"



%@

static const NSUInteger* g_currentScheme = NULL;

@implementation UIColor (CS)

+ (instancetype) colorWithUInteger:(NSUInteger) value {
	const Byte* abgr = (const Byte*) &value;
	return [UIColor colorWithRed:abgr[3] / 255.0 green:abgr[2] / 255.0 blue:abgr[1] / 255.0 alpha:abgr[0] / 255.0];
}

+ (const void*) currentScheme {
	return g_currentScheme;
}

+ (void) setCurrentScheme:(const void*) scheme {
	g_currentScheme = scheme;
}

%@
@end
)";


NSString* headerTemplate2 = @R"(
//
//  UIColor+%1$@.h
//
//  Created by Artem Shimanski
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

extern const void* const %2$@;
)";


NSString* implementationTemplate2 = @R"(
//
//  UIColor+%1$@.m
//
//  Created by Artem Shimanski
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UIColor+%1$@.h"

%2$@

)";

#endif /* templates_h */
