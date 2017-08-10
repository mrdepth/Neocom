//
//  NCDBMapDenormalize+NC.m
//  Neocom
//
//  Created by Artem Shimanski on 22.11.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCDBMapDenormalize+NC.h"

@implementation NCDBMapDenormalize (NC)

+ (NCFetchedCollection<NCDBMapDenormalize*>*) mapDenormalizeWithManagedObjectContext:(NSManagedObjectContext*) managedObjectContext {
	return [[NCFetchedCollection alloc] initWithEntity:@"MapDenormalize" predicateFormat:@"itemID == %@" argumentArray:nil managedObjectContext:managedObjectContext];
}

@end
