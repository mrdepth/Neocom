//
//  main.m
//  EVEBlueprintsParser
//
//  Created by Артем Шиманский on 16.09.14.
//  Copyright (c) 2014 Shimanski Artem. All rights reserved.
//

#import <Foundation/Foundation.h>

NSInteger indentationLevel(NSString* string) {
	NSInteger n = [string lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
	const char* s = [string cStringUsingEncoding:NSUTF8StringEncoding];
	NSInteger i;
	for (i = 0; s[i] == ' ' || s[i] == '\t'; i++);
	return i;
}

NSDictionary* parseYaml(NSString* filePath) {
	NSString* fileContents = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil];

	NSMutableDictionary* root = [NSMutableDictionary new];
	NSMutableArray* stack = [NSMutableArray new];
//	[stack addObject:@{@"node": root, @"indentation":@(0)}];
	NSMutableDictionary* head = root;
	NSInteger headIndentation = 0;
	
	NSInteger lineNumber = 0;
	for (NSString* line in [fileContents componentsSeparatedByString:@"\r\n"]) {
		NSInteger indentation = indentationLevel(line);
		while (indentation <= headIndentation && stack.count > 0) {
			NSDictionary* stackHead = [stack lastObject];
			[stack removeLastObject];
			headIndentation = [stackHead[@"indentation"] integerValue];
			head = stackHead[@"node"];
		}
		
		NSString* truncatedLine = [line substringFromIndex:indentation];
		NSArray* components = [truncatedLine componentsSeparatedByString:@":"];
		if (components.count == 2) {
			NSInteger spaces = indentationLevel(components[1]);
			NSString* value = [components[1] substringFromIndex:spaces];
			
			if (value.length == 0) {
				[stack addObject:@{@"node": head, @"indentation": @(headIndentation)}];
				head = head[components[0]] = [NSMutableDictionary new];
				headIndentation = indentation;
			}
			else {
				head[components[0]] = value;
			}
		}
		else {
			NSLog(@"Error #%ld: \"%@\"", lineNumber, line);
		}
		lineNumber++;
	}
	return root;
}

int main(int argc, const char * argv[]) {
	@autoreleasepool {
		NSDictionary* yaml = parseYaml(@"./blueprints.yaml");
		[yaml enumerateKeysAndObjectsUsingBlock:^(NSString* blueprintTypeID, NSDictionary* info, BOOL *stop) {
			[info[@"activities"] enumerateKeysAndObjectsUsingBlock:^(NSString* activityID, NSDictionary* info, BOOL *stop) {
				[info[@"materials"] enumerateKeysAndObjectsUsingBlock:^(NSString* materialID, NSDictionary* info, BOOL *stop) {
				}];
				NSCAssert([info[@"products"] count] == 1, @"%@: %@", blueprintTypeID, info);
				[info[@"products"] enumerateKeysAndObjectsUsingBlock:^(NSString* materialID, NSDictionary* info, BOOL *stop) {
				}];
			}];
		}];
	}
    return 0;
}
