//
//  NCDBMapDenormalize+NC.h
//  Neocom
//
//  Created by Artem Shimanski on 22.11.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCDBMapDenormalize+CoreDataClass.h"
#import "NCFetchedCollection.h"

@interface NCDBMapDenormalize (NC)
+ (NCFetchedCollection<NCDBMapDenormalize*>*) mapDenormalizeWithManagedObjectContext:(NSManagedObjectContext*) managedObjectContext;

@end
