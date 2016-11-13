//
//  NCDBInvType+NC.m
//  Neocom
//
//  Created by Artem Shimanski on 12.11.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCDBInvType+NC.h"

@implementation NCDBInvType (NC)

+ (NSFetchRequest<NCDBInvType *> *)fetchRequestWithTypeID:(int32_t) typeID {
	NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"InvType"];
	request.predicate = [NSPredicate predicateWithFormat:@"typeID == %d", typeID];
	request.fetchLimit = 1;
	return request;
}

+ (NCFetchedCollection<NCDBInvType*>*) invTypesWithManagedObjectContext:(NSManagedObjectContext*) managedObjectContext {
	return [[NCFetchedCollection alloc] initWithEntity:@"InvType" predicateFormat:@"typeID == %@" argumentArray:nil managedObjectContext:managedObjectContext];
}

- (NCFetchedCollection<NCDBDgmTypeAttribute*>*) attributesMap {
	return [[NCFetchedCollection alloc] initWithEntity:@"DgmTypeAttribute" predicateFormat:@"type == %@ AND attributeType.attributeID==%@" argumentArray:@[self] managedObjectContext:self.managedObjectContext];
}

@end
