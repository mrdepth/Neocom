//
//  NCDBRamActivity+Neocom.m
//  Neocom
//
//  Created by Артем Шиманский on 19.06.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCDBRamActivity+Neocom.h"
#import "NCDatabase.h"

@implementation NCDBRamActivity (Neocom)

+ (instancetype) ramActivityWithActivityID:(int32_t) activityID {
	NCDatabase* database = [NCDatabase sharedDatabase];
	NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"RamActivity"];
	request.predicate = [NSPredicate predicateWithFormat:@"activityID == %d", activityID];
	request.fetchLimit = 1;
	return [[database.managedObjectContext executeFetchRequest:request error:nil] lastObject];
}

@end
