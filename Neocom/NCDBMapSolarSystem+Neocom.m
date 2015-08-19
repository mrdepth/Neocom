//
//  NCDBMapSolarSystem+Neocom.m
//  Neocom
//
//  Created by Артем Шиманский on 16.06.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCDBMapSolarSystem+Neocom.h"
#import "NCDatabase.h"

@implementation NCDBMapSolarSystem (Neocom)

+ (instancetype) mapSolarSystemWithName:(NSString*) name {
	NCDatabase* database = [NCDatabase sharedDatabase];
	NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"MapSolarSystem"];
	request.predicate = [NSPredicate predicateWithFormat:@"solarSystemName == %@", name];
	request.fetchLimit = 1;
	return [[database.managedObjectContext executeFetchRequest:request error:nil] lastObject];
}

+ (instancetype) mapSolarSystemWithSolarSystemID:(int32_t) systemID {
	NCDatabase* database = [NCDatabase sharedDatabase];
	NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"MapSolarSystem"];
	request.predicate = [NSPredicate predicateWithFormat:@"solarSystemID == %d", systemID];
	request.fetchLimit = 1;
	return [[database.managedObjectContext executeFetchRequest:request error:nil] lastObject];
}

@end
