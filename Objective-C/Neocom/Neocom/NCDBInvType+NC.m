//
//  NCDBInvType+NC.m
//  Neocom
//
//  Created by Artem Shimanski on 12.11.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCDBInvType+NC.h"
#import "NCDBInvMetaGroup+CoreDataClass.h"

@implementation NCDBInvType (NC)

+ (NCFetchedCollection<NCDBInvType*>*) invTypesWithManagedObjectContext:(NSManagedObjectContext*) managedObjectContext {
	return [[NCFetchedCollection alloc] initWithEntity:@"InvType" predicateFormat:@"typeID == %@" argumentArray:nil managedObjectContext:managedObjectContext];
}

- (NCFetchedCollection<NCDBDgmTypeAttribute*>*) allAttributes {
	return [[NCFetchedCollection alloc] initWithEntity:@"DgmTypeAttribute" predicateFormat:@"type == %@ AND attributeType.attributeID==%@" argumentArray:@[self] managedObjectContext:self.managedObjectContext];
}

- (NSString*) metaGroupName {
	return self.metaGroup.metaGroupName ?: NSLocalizedString(@"Other", @"Metagroup");
}

@end
