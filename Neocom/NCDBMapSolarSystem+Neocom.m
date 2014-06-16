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
	request.predicate = [NSPredicate predicateWithFormat:@"solarSystemName == %d", name];
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
