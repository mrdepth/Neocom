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
	
	NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Record"];
	fetchRequest.fetchLimit = 1;
	fetchRequest.predicate = [NSPredicate predicateWithFormat:@"recordID == %@", recordID];
	
	NSManagedObjectContext* context = [[NCCache sharedCache] managedObjectContext];
	NCCacheRecord* record = [[context executeFetchRequest:fetchRequest error:nil] lastObject];
	if (!record) {
		record = [[NCCacheRecord alloc] initWithEntity:[NSEntityDescription entityForName:@"Record" inManagedObjectContext:context] insertIntoManagedObjectContext:context];
		record.recordID = recordID;
		record.date = [NSDate date];
		record.expireDate = [NSDate distantPast];
		record.data = [[NCCacheRecordData alloc] initWithEntity:[NSEntityDescription entityForName:@"RecordData" inManagedObjectContext:context] insertIntoManagedObjectContext:context];
	}
	return record;
}

@end
