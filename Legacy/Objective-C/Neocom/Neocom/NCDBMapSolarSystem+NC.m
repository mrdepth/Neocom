//
//  NCDBMapSolarSystem+NC.m
//  Neocom
//
//  Created by Artem Shimanski on 22.11.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCDBMapSolarSystem+NC.h"

@implementation NCDBMapSolarSystem (NC)

+ (NCFetchedCollection<NCDBMapSolarSystem*>*) mapSolarSystemWithManagedObjectContext:(NSManagedObjectContext*) managedObjectContext {
	return [[NCFetchedCollection alloc] initWithEntity:@"MapSolarSystem" predicateFormat:@"solarSystemID == %@" argumentArray:nil managedObjectContext:managedObjectContext];
}


@end
