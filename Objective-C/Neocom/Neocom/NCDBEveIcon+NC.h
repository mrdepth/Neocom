//
//  NCDBEveIcon+NC.h
//  Neocom
//
//  Created by Artem Shimanski on 20.11.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCDBEveIcon+CoreDataClass.h"
#import "NCFetchedCollection.h"

@interface NCDBEveIcon (NC)

+ (instancetype)defaultCategoryIcon;
+ (instancetype)defaultGroupIcon;
+ (instancetype)defaultTypeIcon;
+ (instancetype)iconWithIconFile:(NSString*) file;
+ (NCFetchedCollection<NCDBEveIcon*>*) eveIconsWithManagedObjectContext:(NSManagedObjectContext*) managedObjectContext;


@end
