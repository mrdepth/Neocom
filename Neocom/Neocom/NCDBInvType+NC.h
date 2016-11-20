//
//  NCDBInvType+NC.h
//  Neocom
//
//  Created by Artem Shimanski on 12.11.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCDBInvType+CoreDataClass.h"
#import "NCFetchedCollection.h"

@interface NCDBInvType (NC)

+ (NCFetchedCollection<NCDBInvType*>*) invTypesWithManagedObjectContext:(NSManagedObjectContext*) managedObjectContext;
- (NCFetchedCollection<NCDBDgmTypeAttribute*>*) attributesMap;
	
@end
