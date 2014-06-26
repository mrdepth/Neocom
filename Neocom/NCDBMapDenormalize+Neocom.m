//
//  NCDBMapDenormalize+Neocom.m
//  Neocom
//
//  Created by Артем Шиманский on 19.06.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCDBMapDenormalize+Neocom.h"
#import "NCDatabase.h"

@implementation NCDBMapDenormalize (Neocom)

+ (instancetype) mapDenormalizeWithItemID:(int32_t) itemID {
	NCDatabase* database = [NCDatabase sharedDatabase];
	NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"MapDenormalize"];
	request.predicate = [NSPredicate predicateWithFormat:@"itemID == %d", itemID];
	request.fetchLimit = 1;
	__block NSArray* result;
	if ([NSThread isMainThread])
		result = [database.managedObjectContext executeFetchRequest:request error:nil];
	else
		[database.backgroundManagedObjectContext performBlockAndWait:^{
			result = [database.backgroundManagedObjectContext executeFetchRequest:request error:nil];
		}];
	return result.count > 0 ? result[0] : nil;
}

@end