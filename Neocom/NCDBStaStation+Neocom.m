//
//  NCDBStaStation+Neocom.m
//  Neocom
//
//  Created by Артем Шиманский on 19.06.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCDBStaStation+Neocom.h"
#import "NCDatabase.h"

@implementation NCDBStaStation (Neocom)

+ (instancetype) staStationWithStationID:(int32_t) stationID {
	NCDatabase* database = [NCDatabase sharedDatabase];
	NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"StaStation"];
	request.predicate = [NSPredicate predicateWithFormat:@"stationID == %d", stationID];
	request.fetchLimit = 1;
	return [[database.managedObjectContext executeFetchRequest:request error:nil] lastObject];
}

@end
