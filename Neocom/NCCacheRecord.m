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
	[fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"recordID == %@", recordID]];
	
	NCCacheRecord* record = nil;
	NSArray *fetchedObjects = [context executeFetchRequest:fetchRequest error:nil];
	if (fetchedObjects.count > 0)
		record = fetchedObjects[0];
	else {
		NCCacheRecord* record = [[NCCacheRecord alloc] initWithEntity:entity insertIntoManagedObjectContext:context];
		record.recordID = recordID;
		record.date = [NSDate date];
		record.expireDate = [NSDate distantFuture];
		record.data = [[NCCacheRecordData alloc] initWithEntity:[NSEntityDescription entityForName:@"RecordData" inManagedObjectContext:context] insertIntoManagedObjectContext:context];
		
		record = record;
	}
	return record;
}

@end
