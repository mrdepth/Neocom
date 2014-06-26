//
//  NCDBDgmAttributeType+Neocom.m
//  Neocom
//
//  Created by Артем Шиманский on 12.06.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCDBDgmAttributeType+Neocom.h"
#import "NCDatabase.h"

@implementation NCDBDgmAttributeType (Neocom)

+ (instancetype) dgmAttributeTypeWithAttributeTypeID:(int32_t) attributeTypeID {
	NCDatabase* database = [NCDatabase sharedDatabase];
	NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"DgmAttributeType"];
	request.predicate = [NSPredicate predicateWithFormat:@"attributeID == %d", attributeTypeID];
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
