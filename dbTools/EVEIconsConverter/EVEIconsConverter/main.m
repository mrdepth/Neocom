//
//  main.m
//  EVEIconsConverter
//
//  Created by Artem Shimanski on 05.12.12.
//  Copyright (c) 2012 Artem Shimanski. All rights reserved.
//

#import <Foundation/Foundation.h>

int main(int argc, const char * argv[])
{

	@autoreleasepool {
		NSString *folder = @"./EVEIcons/items";
		NSString *outputFolder = @"./Icons";
		[[NSFileManager defaultManager] createDirectoryAtPath:outputFolder withIntermediateDirectories:YES attributes:nil error:nil];
		NSArray *fileNames = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:folder error:nil];
		
		NSMutableDictionary* map = [NSMutableDictionary dictionary];
		
//		for (NSString* size in sizes)
//			[map setValue:[NSMutableDictionary dictionary] forKey:size];
		
		for (NSString *fileName in fileNames) {
			NSArray *components = [[fileName stringByDeletingPathExtension] componentsSeparatedByString:@"_"];
			if (components.count != 3) {
				map[fileName] = @{@"fileName": fileName, @"size": @(64)};
				continue;
			}
			NSString *a = [components objectAtIndex:0];
			NSString *b = [components objectAtIndex:1];
			NSString *c = [components objectAtIndex:2];
			if ([a integerValue] == 0 || [b integerValue] == 0 || [c integerValue] == 0)
				continue;
			NSInteger size = [b integerValue];
			if (a.length == 1)
				a = [NSString stringWithFormat:@"0%@", a];
			if (c.length == 1)
				c = [NSString stringWithFormat:@"0%@", c];
			
			NSString *fileName2 = [NSString stringWithFormat:@"icon%@_%@.png", a, c];
			
			NSDictionary* record = [map valueForKey:fileName2];
			if (!record)
				[map setValue:@{@"fileName" : fileName, @"size" : @(size)} forKey:fileName2];
			else {
				NSInteger currentSize = [[record valueForKey:@"size"] integerValue];
				if (currentSize < size)
					[map setValue:@{@"fileName" : fileName, @"size" : @(size)} forKey:fileName2];
			}
			
			//NSString *path2 = [folder stringByAppendingPathComponent:fileName2];
			//[[NSFileManager defaultManager] moveItemAtPath:path1 toPath:path2 error:nil];
		}

		for (NSString* key in [map allKeys]) {
			NSString* srcPath = [folder stringByAppendingPathComponent:[[map valueForKey:key] valueForKey:@"fileName"]];
			NSString* dstPath = [outputFolder stringByAppendingPathComponent:key];
			[[NSFileManager defaultManager] copyItemAtPath:srcPath toPath:dstPath error:nil];
		}
	}
	
    return 0;
}

