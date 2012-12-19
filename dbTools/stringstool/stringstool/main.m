//
//  main.m
//  stringstool
//
//  Created by Artem Shimanski on 14.12.12.
//  Copyright (c) 2012 Artem Shimanski. All rights reserved.
//

#import <Foundation/Foundation.h>

NSDictionary* getStrings(NSString* filePath) {
	NSError* error = nil;
	NSString* fileContent = [NSString stringWithContentsOfFile:filePath encoding:NSUTF16StringEncoding error:&error];
	NSMutableDictionary* strings = [NSMutableDictionary dictionary];
	for (NSString* line in [fileContent componentsSeparatedByString:@"\n"]) {
		wchar_t* s = (wchar_t*) [line cStringUsingEncoding:NSUTF32StringEncoding];
		int keyStart = -1;
		int keyEnd = -1;
		int valueStart = -1;
		int valueEnd = -1;
		
		for (int i = 0; s[i]; i++) {
			if (s[i] == L'\\') {
				i++;
			}
			else if (s[i] == L'"') {
				if (keyStart == -1)
					keyStart = i + 1;
				else if (keyEnd == -1)
					keyEnd = i;
				else if (valueStart == -1)
					valueStart = i + 1;
				else if (valueEnd == -1)
					valueEnd = i;
			}
		}
		if (keyEnd > keyStart && valueEnd > valueStart) {
			NSString* key = [line substringWithRange:NSMakeRange(keyStart, keyEnd - keyStart)];
			NSString* value = [line substringWithRange:NSMakeRange(valueStart, valueEnd - valueStart)];
			[strings setValue:value forKey:key];
		}
	}
	return strings;
}

NSString* getString(NSDictionary* strings) {
	NSMutableArray* rows = [NSMutableArray array];
	for (NSString* key in [strings allKeys]) {
		[rows addObject:[NSString stringWithFormat:@"\"%@\" = \"%@\";", key, [strings valueForKey:key]]];
	}
	[rows sortUsingSelector:@selector(compare:)];
	return [rows componentsJoinedByString:@"\n"];
}

int main(int argc, const char * argv[])
{
	@autoreleasepool {
		NSString* inputFile = nil;
		NSString* outputFile = nil;
		int action = 0;

		for (int i = 1; i < argc; i++) {
			if (strcmp(argv[i], "--extract") == 0)
				action = 1;
			else if (strcmp(argv[i], "--replace") == 0)
				action = 2;
			else {
				if (!inputFile) {
					inputFile = [NSString stringWithCString:argv[i] encoding:NSUTF8StringEncoding];
				}
				else
					outputFile = [NSString stringWithCString:argv[i] encoding:NSUTF8StringEncoding];
			}
		}
		
		NSMutableDictionary* input = [NSMutableDictionary dictionaryWithDictionary:getStrings(inputFile)];
		NSMutableDictionary* output = [NSMutableDictionary dictionaryWithDictionary:getStrings(outputFile)];
		
		if (action == 1) {
			for (NSString* value in [input allValues])
				[output setValue:value forKey:value];
		}
		else if (action == 2) {
			for (NSString* key in [output allKeys]) {
				NSString* value = [input valueForKey:key];
				[output setValue:value forKey:key];
			}
		}
		[getString(output) writeToFile:outputFile atomically:YES encoding:NSUTF16StringEncoding error:nil];
	}
    return 0;
}

