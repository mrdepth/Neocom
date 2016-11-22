//
//  NCDBStaStation+NC.m
//  Neocom
//
//  Created by Artem Shimanski on 22.11.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCDBStaStation+NC.h"

@implementation NCDBStaStation (NC)

+ (NCFetchedCollection<NCDBStaStation*>*) staStationsWithManagedObjectContext:(NSManagedObjectContext*) managedObjectContext {
	return [[NCFetchedCollection alloc] initWithEntity:@"StaStation" predicateFormat:@"stationID == %@" argumentArray:nil managedObjectContext:managedObjectContext];
}

@end
