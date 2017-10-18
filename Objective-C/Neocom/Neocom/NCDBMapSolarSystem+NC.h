//
//  NCDBMapSolarSystem+NC.h
//  Neocom
//
//  Created by Artem Shimanski on 22.11.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCDBMapSolarSystem+CoreDataClass.h"
#import "NCFetchedCollection.h"

@interface NCDBMapSolarSystem (NC)
+ (NCFetchedCollection<NCDBMapSolarSystem*>*) mapSolarSystemWithManagedObjectContext:(NSManagedObjectContext*) managedObjectContext;

@end
