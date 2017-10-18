//
//  NCDBStaStation+NC.h
//  Neocom
//
//  Created by Artem Shimanski on 22.11.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCDBStaStation+CoreDataClass.h"
#import "NCFetchedCollection.h"

@interface NCDBStaStation (NC)
+ (NCFetchedCollection<NCDBStaStation*>*) staStationsWithManagedObjectContext:(NSManagedObjectContext*) managedObjectContext;

@end
