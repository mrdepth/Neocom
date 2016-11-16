//
//  main.m
//  clrconvert
//
//  Created by Artem Shimanski on 16.11.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

NSString* sourceMethodTemplate = @"\
+ (instancetype) %@ {\n\
	return [UIColor colorWithUInteger:0x%@];\n\
}\n\n";

NSString* headerMethodTemplate = @"+ (instancetype) %@;\n";

NSString* headerTemplate = @"\
//\n\
//  UIColor+%1$@.h\n\
//  Neocom\n\
//\n\
//  Created by Artem Shimanski\n\
//  Copyright © 2016 Artem Shimanski. All rights reserved.\n\
//\n\
\n\
#import <UIKit/UIKit.h>\n\
\n\
@interface UIColor (%1$@)\n\
\n\
+ (instancetype) colorWithUInteger:(NSUInteger) value;\n\
%2$@\n\
@end\n";

NSString* sourceTemplate = @"\
//\n\
//  UIColor+%1$@.m\n\
//  Neocom\n\
//\n\
//  Created by Artem Shimanski\n\
//  Copyright © 2016 Artem Shimanski. All rights reserved.\n\
//\n\
\n\
#import \"UIColor+%1$@.h\"\n\
\n\
@implementation UIColor (%1$@)\n\
\n\
+ (instancetype) colorWithUInteger:(NSUInteger) value {\n\
const Byte* abgr = (const Byte*) &value;\n\
return [UIColor colorWithRed:abgr[3] / 255.0 green:abgr[2] / 255.0 blue:abgr[1] / 255.0 alpha:abgr[0] / 255.0];\n\
}\n\
\n\
%2$@\
@end\n";

@implementation NSColor(NC)

- (NSString*) hexString {
	NSColor* color = [self colorUsingColorSpace:[NSColorSpace deviceRGBColorSpace]];
	CGFloat rgba[4];
	[color getRed:&rgba[0] green:&rgba[1] blue:&rgba[2] alpha:&rgba[3]];
	for (int i = 0; i < 4; i++) {
		rgba[i] = round(rgba[i] * 255.0);
	}
	return [NSString stringWithFormat:@"%02x%02x%02x%02x", (int) rgba[0], (int) rgba[1], (int) rgba[2], (int) rgba[3]];
};

- (NSString*) methodNameWithKey:(NSString*) key {
	NSMutableString* methodName = [key mutableCopy];
	[methodName replaceCharactersInRange:NSMakeRange(0, 1) withString:[[methodName substringWithRange:NSMakeRange(0, 1)] lowercaseString]];
	[methodName appendString:@"Color"];
	return methodName;
}

- (NSString*) sourceImplementationWithKey:(NSString*) key {
	return [NSString stringWithFormat:sourceMethodTemplate, [self methodNameWithKey:key], [self hexString]];
}

- (NSString*) sourceHeaderWithKey:(NSString*) key {
	return [NSString stringWithFormat:headerMethodTemplate, [self methodNameWithKey:key]];
}

@end

int main(int argc, const char * argv[]) {
	@autoreleasepool {
		if (argc != 3)
			return 1;
		else {
			NSString* input = [NSString stringWithUTF8String:argv[1]];
			NSString* output = [NSString stringWithUTF8String:argv[2]];
			NSString* name = [[input lastPathComponent] stringByDeletingPathExtension];
			NSColorList* colorList = [[NSColorList alloc] initWithName:name fromFile:input];
			NSMutableString* header = [NSMutableString new];
			NSMutableString* source = [NSMutableString new];
			for (NSString* key in colorList.allKeys) {
				NSColor* color = [colorList colorWithKey:key];
				[header appendString:[color sourceHeaderWithKey:key]];
				[source appendString:[color sourceImplementationWithKey:key]];
			}
			NSString* s = [NSString stringWithFormat:headerTemplate, name, header];
			[s writeToFile:[output stringByAppendingPathComponent:[NSString stringWithFormat:@"UIColor+%@.h", name]] atomically:YES encoding:NSUTF8StringEncoding error:nil];
			s = [NSString stringWithFormat:sourceTemplate, name, source];
			[s writeToFile:[output stringByAppendingPathComponent:[NSString stringWithFormat:@"UIColor+%@.m", name]] atomically:YES encoding:NSUTF8StringEncoding error:nil];
		}
	}
    return 0;
}
