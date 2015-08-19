//
//  NCDBMapRegion+Neocom.m
//  Neocom
//
//  Created by Артем Шиманский on 19.06.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCDBMapRegion+Neocom.h"
#import "NCDatabase.h"

@implementation NCDBMapRegion (Neocom)

+ (instancetype) mapRegionWithRegionID:(int32_t) regionID {
	NCDatabase* database = [NCDatabase sharedDatabase];
	NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"MapRegion"];
	request.predicate = [NSPredicate predicateWithFormat:@"regionID == %d", regionID];
	request.fetchLimit = 1;
	return [[database.managedObjectContext executeFetchRequest:request error:nil] lastObject];
}

@end
