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
	    NSFileManager* fileManager = [NSFileManager defaultManager];
		NSString* inputFolder = @"./EVETypes";
		NSString* outputFolder = @"./Types";
		NSString* oldTypes = @"./OldTypes";
		NSArray* inputFiles = [fileManager contentsOfDirectoryAtPath:inputFolder error:nil];
		NSArray* oldFiles = [fileManager contentsOfDirectoryAtPath:oldTypes error:nil];
		NSMutableArray* oldTypeIDs = [NSMutableArray array];
		
		for (NSString* fileName in oldFiles)
			if ([[fileName pathExtension] compare:@"png"] == NSOrderedSame) {
				[oldTypeIDs addObject:[fileName stringByDeletingPathExtension]];
			}
		
		
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
			
			/*NSString* imageName = [md5s valueForKey:md5];
			if (!imageName) {
				imageName = typeID;
				[md5s setValue:imageName forKey:md5];
				[data writeToFile:outputPath atomically:YES];
			}
			[sqlRows appendFormat:@"UPDATE eveDB.invTypes SET imageName=\"%@\" WHERE typeID = %@;\n", imageName, typeID];
			[data release];*/
			
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
			NSString* oldImageName = [record valueForKey:@"imageName"];
			for (NSString* typeID in [record valueForKey:@"typeIDs"]) {
				if ([oldTypeIDs containsObject:typeID]) {
					[record setValue:typeID forKey:@"imageName"];
					break;
				}
			}
			NSString* imageName = [record valueForKey:@"imageName"];
			if ([imageName compare:oldImageName] != NSOrderedSame)
				[[NSFileManager defaultManager] moveItemAtPath:[NSString stringWithFormat:@"%@/%@.png", outputFolder, oldImageName]
														toPath:[NSString stringWithFormat:@"%@/%@.png", outputFolder, imageName]
														 error:nil];
			for (NSString* typeID in [record valueForKey:@"typeIDs"]) {
				[sqlRows appendFormat:@"UPDATE eveDB.invTypes SET imageName=\"%@\" WHERE typeID = %@;\n", imageName, typeID];
			}
		}
		
		[sqlRows appendString:@"COMMIT TRANSACTION;"];
		[sqlRows writeToFile:@"typesMap.sql" atomically:YES encoding:NSUTF8StringEncoding error:nil];
	    // insert code here...
	    NSLog(@"Hello, World!");
	    
	}
    return 0;
}