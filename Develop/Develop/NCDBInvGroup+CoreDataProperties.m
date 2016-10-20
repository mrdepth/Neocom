//
//  NCDBInvGroup+CoreDataProperties.m
//  Develop
//
//  Created by Artem Shimanski on 20.10.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCDBInvGroup+CoreDataProperties.h"

@implementation NCDBInvGroup (CoreDataProperties)

+ (NSFetchRequest<NCDBInvGroup *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"InvGroup"];
}

@dynamic groupID;
@dynamic groupName;
@dynamic published;
@dynamic category;
@dynamic certificates;
@dynamic icon;
@dynamic npcGroups;
@dynamic types;

@end
