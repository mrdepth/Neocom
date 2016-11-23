//
//  NCCacheRecordData.m
//  Neocom
//
//  Created by Artem Shimanski on 23.11.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCCacheRecord+CoreDataProperties.h"
#import "NCCacheRecordData+CoreDataProperties.h"

@implementation NCCacheRecordData

- (void) willChangeValueForKey:(NSString *)key {
	[super willChangeValueForKey:key];
	if ([key isEqualToString:@"data"])
		[self.record willChangeValueForKey:@"object"];
}

- (void) didChangeValueForKey:(NSString *)key {
	[super didChangeValueForKey:key];
	if ([key isEqualToString:@"data"])
		[self.record didChangeValueForKey:@"object"];
}

@end
