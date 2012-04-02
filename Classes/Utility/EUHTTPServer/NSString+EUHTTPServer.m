//
//  NSString+EUHTTPServer.m
//  EVEUniverse
//
//  Created by Artem Shimanski on 30.03.12.
//  Copyright (c) 2012 Belprog. All rights reserved.
//

#import "NSString+EUHTTPServer.h"

@implementation NSString (EUHTTPServer)
- (NSDictionary*) httpHeaderValueFields {
	NSArray* fields = [self componentsSeparatedByString:@";"];
	NSMutableDictionary* dic = [NSMutableDictionary dictionaryWithCapacity:fields.count];
	
	for (NSString* field in fields) {
		NSArray* components = [field componentsSeparatedByString:@"="];
		if (components.count == 2) {
			NSString* key = [[components objectAtIndex:0] stringByReplacingOccurrencesOfString:@" " withString:@""];
			NSString* value = [[components objectAtIndex:1] stringByReplacingOccurrencesOfString:@"\"" withString:@""];
			[dic setValue:value forKey:[key lowercaseString]];
		}
	}
	return dic;
}

- (NSDictionary*) httpHeaders {
	NSArray* headers = [self componentsSeparatedByString:@"\r\n"];
	NSMutableDictionary* dic = [NSMutableDictionary dictionaryWithCapacity:headers.count];

	for (NSString* header in headers) {
		NSArray* components = [header componentsSeparatedByString:@":"];
		if (components.count == 2) {
			NSString* key = [components objectAtIndex:0];
			NSString* value = [components objectAtIndex:1];
			[dic setValue:value forKey:key];
		}
	}
	return dic;
}

- (NSDictionary*) httpGetArguments {
	NSArray* arguments = [self componentsSeparatedByString:@"&"];
	NSMutableDictionary* dic = [NSMutableDictionary dictionaryWithCapacity:arguments.count];
	for (NSString *argument in arguments) {
		NSArray *components = [argument componentsSeparatedByString:@"="];
		if (components.count == 2) {
			NSString *value = [[components objectAtIndex:1] stringByReplacingOccurrencesOfString:@"+" withString:@" "];
			value = [value stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
			[dic setValue:value forKey:[components objectAtIndex:0]];
		}
	}
	return dic;
}

@end
