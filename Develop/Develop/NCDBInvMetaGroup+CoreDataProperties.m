//
//  NCDBInvMetaGroup+CoreDataProperties.m
//  Develop
//
//  Created by Artem Shimanski on 20.10.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCDBInvMetaGroup+CoreDataProperties.h"

@implementation NCDBInvMetaGroup (CoreDataProperties)

+ (NSFetchRequest<NCDBInvMetaGroup *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"InvMetaGroup"];
}

@dynamic metaGroupID;
@dynamic metaGroupName;
@dynamic icon;
@dynamic types;

@end
