//
//  main.m
//  EVETypesConverter
//
//  Created by Mr. Depth on 1/20/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NSData+MD5.h"

int main (int argc, const char * argv[])
{

	@autoreleasepool {
		if (argc == 4) {
			NSFileManager* fileManager = [NSFileManager defaultManager];
			NSString* inputFolder = [NSString stringWithUTF8String:argv[1]];
			NSString* outputFolder = [NSString stringWithUTF8String:argv[2]];
			NSArray* inputFiles = [fileManager contentsOfDirectoryAtPath:inputFolder error:nil];
			
			inputFiles = [inputFiles sortedArrayUsingSelector:@selector(compare:)];
			[fileManager removeItemAtPath:outputFolder error:nil];
			[fileManager createDirectoryAtPath:outputFolder withIntermediateDirectories:YES attributes:nil error:nil];
			NSMutableDictionary* types = [NSMutableDictionary dictionary];
			for (NSString* fileName in inputFiles) {
				fileName = [fileName lowercaseString];
				if ([[fileName pathExtension] compare:@"png"] == NSOrderedSame) {
					NSArray* components = [[fileName stringByDeletingPathExtension] componentsSeparatedByString:@"_"];
					NSString* typeID = [components objectAtIndex:0];
					NSString* size = [components objectAtIndex:1];
					NSMutableDictionary* type = [types valueForKey:typeID];
					if (!type) {
						type = [NSMutableDictionary dictionaryWithObjectsAndKeys:fileName, @"fileName", size, @"size", typeID, @"typeID", nil];
						[types setValue:type forKey:typeID];
					}
					else {
						NSInteger size1 = [[type valueForKey:@"size"] integerValue];
						NSInteger size2 = [size integerValue];
						if (size1 < 64 && size2 >= 64) {
							[type setValue:fileName forKey:@"fileName"];
							[type setValue:size forKey:@"size"];
						}
					}
				}
			}
			
			NSMutableDictionary* md5s = [NSMutableDictionary dictionary];
			NSMutableString* sqlRows = [NSMutableString stringWithString:@"ALTER TABLE eveDB.invTypes ADD imageName varchar(10);\nBEGIN TRANSACTION;\n"];
			
			for (NSDictionary* type in [types allValues]) {
				NSInteger size = [[type valueForKey:@"size"] integerValue];
				NSString* typeID = [type valueForKey:@"typeID"];
				NSString* inputPath = [inputFolder stringByAppendingPathComponent:[type valueForKey:@"fileName"]];
				NSString* outputPath = [NSString stringWithFormat:@"%@/%@.png", outputFolder, typeID];
				
				NSData* data = nil;
				
				if (size != 64) {
					NSImage* image = [[NSImage alloc] initWithContentsOfFile:inputPath];
					[image setSize:NSMakeSize(64, 64)];
					NSArray* representations = [image representations];
					representations = representations;
					NSBitmapImageRep* rep = representations[0];
					data = [rep representationUsingType:NSPNGFileType properties:nil];
					
				}
				else
					data = [[NSData alloc] initWithContentsOfFile:inputPath];
				NSString* md5 = [data md5];
				
				NSMutableDictionary* record = [md5s valueForKey:md5];
				if (!record) {
					record = [NSMutableDictionary dictionary];
					[record setValue:typeID forKey:@"imageName"];
					[record setValue:[NSMutableArray arrayWithObject:typeID] forKey:@"typeIDs"];
					[md5s setValue:record forKey:md5];
					[data writeToFile:outputPath atomically:YES];
				}
				else
					[[record valueForKey:@"typeIDs"] addObject:typeID];
				[data release];
			}
			
			for (NSDictionary* record in [md5s allValues]) {
				NSString* imageName = [record valueForKey:@"imageName"];
				for (NSString* typeID in [record valueForKey:@"typeIDs"]) {
					[sqlRows appendFormat:@"UPDATE eveDB.invTypes SET imageName=\"%@\" WHERE typeID = %@;\n", imageName, typeID];
				}
			}
			
			[sqlRows appendString:@"COMMIT TRANSACTION;"];
			[sqlRows writeToFile:[NSString stringWithUTF8String:argv[3]] atomically:YES encoding:NSUTF8StringEncoding error:nil];
		}
	}
    return 0;
}