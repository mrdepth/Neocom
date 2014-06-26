//
//  NCDBInvGroup+Neocom.m
//  Neocom
//
//  Created by Артем Шиманский on 12.06.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCDBInvGroup+Neocom.h"
#import "NCDatabase.h"

@implementation NCDBInvGroup (Neocom)

+ (instancetype) invGroupWithGroupID:(int32_t) groupID {
	NCDatabase* database = [NCDatabase sharedDatabase];
	NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"InvGroup"];
	request.predicate = [NSPredicate predicateWithFormat:@"groupID == %d", groupID];
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
