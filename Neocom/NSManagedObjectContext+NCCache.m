//
//  NSManagedObjectContext+NCCache.m
//  Neocom
//
//  Created by Артем Шиманский on 28.08.15.
//  Copyright (c) 2015 Artem Shimanski. All rights reserved.
//

#import "NSManagedObjectContext+NCCache.h"
#import "NCCacheRecord.h"

@implementation NSManagedObjectContext (NCCache)

- (NCCacheRecord*) cacheRecordWithRecordID:(NSString*) recordID {
	
	NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Record"];
	fetchRequest.fetchLimit = 1;
	fetchRequest.predicate = [NSPredicate predicateWithFormat:@"recordID == %@", recordID];
	
	NCCacheRecord* record = [[self executeFetchRequest:fetchRequest error:nil] lastObject];
	if (!record) {
		record = [[NCCacheRecord alloc] initWithEntity:[NSEntityDescription entityForName:@"Record" inManagedObjectContext:self] insertIntoManagedObjectContext:self];
		record.recordID = recordID;
		record.date = [NSDate date];
		record.expireDate = [NSDate distantPast];
		record.data = [[NCCacheRecordData alloc] initWithEntity:[NSEntityDescription entityForName:@"RecordData" inManagedObjectContext:self] insertIntoManagedObjectContext:self];
	}
	return record;
}

@end
