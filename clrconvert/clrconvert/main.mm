//
//  main.m
//  clrconvert
//
//  Created by Artem Shimanski on 16.11.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import "templates.h"


@implementation NSColor(NC)

+ (instancetype) colorWithUInteger:(NSUInteger) value {
	const Byte* abgr = (const Byte*) &value;
	return [NSColor colorWithDeviceRed:abgr[3] / 255.0 green:abgr[2] / 255.0 blue:abgr[1] / 255.0 alpha:abgr[0] / 255.0];
}


- (NSString*) hexString {
	NSColor* color = [self colorUsingColorSpace:[NSColorSpace deviceRGBColorSpace]];
	CGFloat rgba[4];
	[color getRed:&rgba[0] green:&rgba[1] blue:&rgba[2] alpha:&rgba[3]];
	for (int i = 0; i < 4; i++) {
		rgba[i] = round(rgba[i] * 255.0);
	}
	return [NSString stringWithFormat:@"0x%02x%02x%02x%02x", (int) rgba[0], (int) rgba[1], (int) rgba[2], (int) rgba[3]];
};

- (NSString*) methodNameWithKey:(NSString*) key {
	NSMutableString* methodName = [key mutableCopy];
	[methodName replaceCharactersInRange:NSMakeRange(0, 1) withString:[[methodName substringWithRange:NSMakeRange(0, 1)] lowercaseString]];
	[methodName appendString:@"Color"];
	return methodName;
}

- (NSString*) sourceImplementationWithKey:(NSString*) key {
	return nil;
	//return [NSString stringWithFormat:sourceMethodTemplate, [self methodNameWithKey:key], key];
}

- (NSString*) sourceHeaderWithKey:(NSString*) key {
	return nil;
	//return [NSString stringWithFormat:headerMethodTemplate, [self methodNameWithKey:key]];
}

@end

/*NSDictionary* loadColorSchemesIn(NSString* headerPath, NSString* implementationPath) {
	NSString* header = [NSString stringWithContentsOfFile:headerPath encoding:NSUTF8StringEncoding error:nil];
	NSString* implementation = [NSString stringWithContentsOfFile:implementationPath encoding:NSUTF8StringEncoding error:nil];
	if (!header || !implementation)
		return nil;
	
	NSRegularExpression* regex = [NSRegularExpression regularExpressionWithPattern:CSSchemeNameRegEx options:NSRegularExpressionDotMatchesLineSeparators error:nil];
	NSTextCheckingResult* result = [regex firstMatchInString:header options:0 range:NSMakeRange(0, header.length)];
	NSArray* colorSchemeNames;
	if (result)
		colorSchemeNames = [[header substringWithRange:[result rangeAtIndex:1]] componentsSeparatedByString:@",\n"];
	if (!colorSchemeNames)
		return nil;

	regex = [NSRegularExpression regularExpressionWithPattern:CSColorNameRegEx options:NSRegularExpressionDotMatchesLineSeparators error:nil];
	result = [regex firstMatchInString:implementation options:0 range:NSMakeRange(0, implementation.length)];
	NSArray* colorNames;
	if (result)
		colorNames = [[implementation substringWithRange:[result rangeAtIndex:1]] componentsSeparatedByString:@",\n"];
	if (!colorNames)
		return nil;
	
	regex = [NSRegularExpression regularExpressionWithPattern:g_colorsRegEx options:NSRegularExpressionDotMatchesLineSeparators error:nil];
	result = [regex firstMatchInString:implementation options:0 range:NSMakeRange(0, implementation.length)];
	if (result) {
		NSMutableDictionary* colorSchemes = [NSMutableDictionary new];
		
		regex = [NSRegularExpression regularExpressionWithPattern:g_colorsItemRegEx options:NSRegularExpressionDotMatchesLineSeparators error:nil];
		NSArray* matches = [regex matchesInString:implementation options:0 range:[result rangeAtIndex:1]];
		
		int i = 0;
		for (NSString* colorSchemeName in colorSchemeNames) {
			NSMutableDictionary* scheme = [NSMutableDictionary new];
			NSTextCheckingResult* result = matches[i];
			int j = 0;
			for (NSString* s in [[implementation substringWithRange:[result rangeAtIndex:1]] componentsSeparatedByString:@","]) {
				NSScanner* scanner = [NSScanner scannerWithString:s];
				unsigned int hex = 0;
				NSCParameterAssert([scanner scanHexInt:&hex]);
				scheme[colorNames[j++]] = [NSColor colorWithUInteger:hex];
			}
			colorSchemes[colorSchemeName] = scheme;
			i++;
		}
		return colorSchemes;
	}
	
	return nil;
}*/

NSString* capitalizeFirstLetter(NSString* s) {
	return [s stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:[[s substringWithRange:NSMakeRange(0, 1)] uppercaseString]];
}

NSString* colorSchemeName(NSString* name) {
	return [NSString stringWithFormat:@"CSScheme%@", capitalizeFirstLetter(name)];
}

NSString* colorName(NSString* key) {
	return [NSString stringWithFormat:@"CSColorName%@", capitalizeFirstLetter(key)];
}

NSDictionary* createColorScheme(NSColorList* colorList) {
	NSMutableDictionary* colorScheme = [NSMutableDictionary new];
	for (NSString* key in colorList.allKeys) {
		colorScheme[colorName(key)] = [[colorList colorWithKey:key] colorUsingColorSpace:[NSColorSpace deviceRGBColorSpace]];
	}
	return colorScheme;
}

NSString* CSSchemeName(NSDictionary* colorSchemes) {
	NSArray* keys = [colorSchemes.allKeys sortedArrayUsingSelector:@selector(compare:)];
	return [NSString stringWithFormat:CSSchemeNameTemplate, [keys componentsJoinedByString:@",\n"]];
};

NSArray<NSString*>* colorNames(NSDictionary* scheme) {
	return [scheme.allKeys sortedArrayUsingSelector:@selector(compare:)];
}

NSString* CSColorName(NSDictionary* colorScheme) {
	return [NSString stringWithFormat:CSColorNameTemplate, [colorNames(colorScheme) componentsJoinedByString:@",\n"]];
};

NSString* methodNameWithKey(NSString* key) {
	NSMutableString* methodName = [[key stringByReplacingOccurrencesOfString:@"CSColorName" withString:@""] mutableCopy];
	[methodName replaceCharactersInRange:NSMakeRange(0, 1) withString:[[methodName substringWithRange:NSMakeRange(0, 1)] lowercaseString]];
	[methodName appendString:@"Color"];
	return methodName;
}

NSString* methodHeader(NSString* key) {
	return [NSString stringWithFormat:methodDeclarationTemplate, methodNameWithKey(key)];
}

NSString* methodImplementation(NSString* key) {
	return [NSString stringWithFormat:methodImplementationTemplate, methodNameWithKey(key), key];
}

NSString* colors(NSDictionary* colorScheme, NSString* name) {
	NSMutableArray* array = [NSMutableArray new];
	for (NSString* key in colorNames(colorScheme)) {
		NSColor* color = colorScheme[key] ?: [NSColor clearColor];
		[array addObject:[color hexString]];
	}

	return [NSString stringWithFormat:g_colorsTemplate, name, [array componentsJoinedByString:@","]];
}

int main(int argc, const char * argv[]) {
	@autoreleasepool {
		if (argc != 3)
			return 1;
		else {
			
			NSString* input = [NSString stringWithUTF8String:argv[1]];
			NSString* sourceOutput = [NSString stringWithUTF8String:argv[2]];
			NSString* name = [[input lastPathComponent] stringByDeletingPathExtension];
			NSString* headerFilePath = [sourceOutput stringByAppendingPathComponent:@"UIColor+CS.h"];
			NSString* implementationFilePath = [sourceOutput stringByAppendingPathComponent:@"UIColor+CS.m"];
			NSString* headerFilePath2 = [sourceOutput stringByAppendingPathComponent:[NSString stringWithFormat:@"UIColor+%@.h", name]];
			NSString* implementationFilePath2 = [sourceOutput stringByAppendingPathComponent:[NSString stringWithFormat:@"UIColor+%@.m", name]];
			
			
			NSDictionary* cs = createColorScheme([[NSColorList alloc] initWithName:name fromFile:input]);
			NSString* csName = colorSchemeName(name);
			NSArray* cn = colorNames(cs);
			
			NSMutableString* methodHeaders = [NSMutableString new];
			NSMutableString* methodImplementations = [NSMutableString new];

			for (NSString* key in cn) {
				[methodHeaders appendString:methodHeader(key)];
				[methodImplementations appendString:methodImplementation(key)];
			}
			
			NSString* header = [NSString stringWithFormat:headerTemplate, methodHeaders];
			NSString* implementation = [NSString stringWithFormat:implementationTemplate,
										CSColorName(cs),
										methodImplementations];
			[header writeToFile:headerFilePath atomically:YES encoding:NSUTF8StringEncoding error:nil];
			[implementation writeToFile:implementationFilePath atomically:YES encoding:NSUTF8StringEncoding error:nil];
			
			[[NSString stringWithFormat:headerTemplate2, name, csName] writeToFile:headerFilePath2 atomically:YES encoding:NSUTF8StringEncoding error:nil];
			
			[[NSString stringWithFormat:implementationTemplate2, name, colors(cs, csName)] writeToFile:implementationFilePath2 atomically:YES encoding:NSUTF8StringEncoding error:nil];
			
			/*NSMutableString* header = [NSMutableString new];
			NSMutableString* source = [NSMutableString new];
			NSMutableDictionary* plt = [NSMutableDictionary new];
			for (NSString* key in [colorList.allKeys sortedArrayUsingSelector:@selector(compare:)]) {
				NSColor* color = [colorList colorWithKey:key];
				[header appendString:[color sourceHeaderWithKey:key]];
				[source appendString:[color sourceImplementationWithKey:key]];
				plt[key] = color;
			}
			[NSKeyedArchiver archiveRootObject:plt toFile:paletteOutput];
			NSString* s = [NSString stringWithFormat:headerTemplate, header];
			[s writeToFile:[sourceOutput stringByAppendingPathComponent:@"UIColor+Palette.h"] atomically:YES encoding:NSUTF8StringEncoding error:nil];
			//s = [NSString stringWithFormat:sourceTemplate, source];
			[s writeToFile:[sourceOutput stringByAppendingPathComponent:@"UIColor+Palette.m"] atomically:YES encoding:NSUTF8StringEncoding error:nil];*/
		}
	}
    return 0;
}
