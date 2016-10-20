//
//  NCDBNpcGroup+CoreDataProperties.m
//  Develop
//
//  Created by Artem Shimanski on 20.10.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCDBNpcGroup+CoreDataProperties.h"

@implementation NCDBNpcGroup (CoreDataProperties)

+ (NSFetchRequest<NCDBNpcGroup *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"NpcGroup"];
}

@dynamic npcGroupName;
@dynamic group;
@dynamic icon;
@dynamic parentNpcGroup;
@dynamic supNpcGroups;

@end
