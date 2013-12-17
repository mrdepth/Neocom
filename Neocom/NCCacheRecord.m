//
//  NCCacheRecord.m
//  Neocom
//
//  Created by Artem Shimanski on 12.12.13.
//  Copyright (c) 2013 Artem Shimanski. All rights reserved.
//

#import "NCCacheRecord.h"
#import "NCCache.h"

@implementation NCCacheRecord

@dynamic recordID;
@dynamic data;
@dynamic date;
@dynamic expireDate;
@dynamic section;

+ (instancetype) cacheRecordWithRecordID:(NSString*) recordID {
	
	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
	NSManagedObjectContext* context = [[NCCache sharedCache] managedObjectContext];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"Record" inManagedObjectContext:context];
	[fetchRequest setEntity:entity];
	
	NSArray *fetchedObjects = [context executeFetchRequest:fetchRequest error:nil];
	return fetchedObjects.count > 0 ? fetchedObjects[0] : nil;
}

@end
