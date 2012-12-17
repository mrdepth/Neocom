//
//  main.m
//  stringstool
//
//  Created by Artem Shimanski on 14.12.12.
//  Copyright (c) 2012 Artem Shimanski. All rights reserved.
//

#import <Foundation/Foundation.h>

NSDictionary* getStrings(NSString* fileContent) {
	return nil;
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
		
		NSMutableDictionary* output = [NSMutableDictionary dictionaryWithDictionary:getStrings(outputFile)];
		NSMutableDictionary* input = [NSMutableDictionary dictionaryWithDictionary:getStrings(inputFile)];
		
		if (action == 1) {
			for (NSString* value in [input allValues])
				[output setValue:value forKey:value];
		}
		else if (action == 2) {
			
		}
	}
    return 0;
}

