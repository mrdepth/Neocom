//
//  main.m
//  EVEIconsIDsParser
//
//  Created by Artem Shimanski on 09.09.13.
//  Copyright (c) 2013 Artem Shimanski. All rights reserved.
//

#import <Foundation/Foundation.h>

int main(int argc, const char * argv[])
{

	@autoreleasepool {
		NSStringEncoding encoding;
		NSError* error = nil;
		NSString* fileContents = [NSString stringWithContentsOfFile:@"eveDB/iconIDs.yaml" usedEncoding:&encoding error:&error];
		fileContents = [fileContents stringByReplacingOccurrencesOfString:@"\r" withString:@""];
		
		NSMutableArray* records = [NSMutableArray new];
		NSMutableDictionary* record;
		int state = 0;
		NSString* lastKey = nil;
		for (NSString* line in [fileContents componentsSeparatedByString:@"\n"]) {
			NSArray* components = [line componentsSeparatedByString:@": "];
			if (components.count == 1) {
				NSInteger i = [line rangeOfString:@":"].location;
				if (i == NSNotFound) {
					if (lastKey) {
						const char* s = [line cStringUsingEncoding:NSUTF8StringEncoding];
						NSInteger n = [line lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
						for (i = 0; i < n; i++) {
							if (s[i] != ' ' && s[i] != '\t')
								break;
						}
						NSString* value = [line substringFromIndex:i];
						record[lastKey] = [NSString stringWithFormat:@"%@ %@", record[lastKey], value];
					}
				}
				else {
					record = [NSMutableDictionary new];
					record[@"iconID"] = [line substringToIndex:[line rangeOfString:@":"].location];
					[records addObject:record];
				}
			}
			else {
				NSString* key = components[0];
				key = [key stringByReplacingOccurrencesOfString:@" " withString:@""];
				record[key] = [components[1] stringByReplacingOccurrencesOfString:@"'" withString:@""];
				if (state == 2)
					state = 0;
				else
					state++;
				lastKey = key;
			}
		}
		
		NSMutableString* sql = [NSMutableString new];
		[sql appendString:@"CREATE TABLE \"eveIcons\" (\n\
		 \"iconID\" integer NOT NULL,\n\
		 \"iconFile\" varchar(500) NOT NULL,\n\
		 \"description\" text NOT NULL,\n\
		 PRIMARY KEY (\"iconID\")\n\
		 );\n\n"];
		
		for (NSDictionary* record in records) {
			[sql appendFormat:@"INSERT INTO eveIcons VALUES (%@, \"%@\", \"%@\");\n", record[@"iconID"], record[@"iconFile"] ? record[@"iconFile"] : @"", record[@"description"] ? record[@"description"] : @""];
		}
		[sql writeToFile:@"eveDB/eveIcons.sql" atomically:YES encoding:NSUTF8StringEncoding error:nil];
	}
    return 0;
}

/*

 0:
 description: Unknown
 iconFile: '07_15'
 15:
 description: Asteroid
 iconFile: '05_11'

*/