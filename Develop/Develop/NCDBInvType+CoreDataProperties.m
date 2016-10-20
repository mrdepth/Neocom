//
//  NCDBInvType+CoreDataProperties.m
//  Develop
//
//  Created by Artem Shimanski on 20.10.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCDBInvType+CoreDataProperties.h"

@implementation NCDBInvType (CoreDataProperties)

+ (NSFetchRequest<NCDBInvType *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"InvType"];
}

@dynamic basePrice;
@dynamic capacity;
@dynamic mass;
@dynamic metaGroupName;
@dynamic metaLevel;
@dynamic portionSize;
@dynamic published;
@dynamic radius;
@dynamic typeID;
@dynamic typeName;
@dynamic volume;
@dynamic attributes;
@dynamic blueprintType;
@dynamic certificates;
@dynamic controlTower;
@dynamic controlTowerResources;
@dynamic denormalize;
@dynamic dgmppItem;
@dynamic effects;
@dynamic group;
@dynamic hullType;
@dynamic icon;
@dynamic indRequiredSkills;
@dynamic installationTypeContents;
@dynamic marketGroup;
@dynamic masterySkills;
@dynamic materials;
@dynamic metaGroup;
@dynamic parentType;
@dynamic products;
@dynamic race;
@dynamic requiredForSkill;
@dynamic requiredSkills;
@dynamic stations;
@dynamic typeDescription;
@dynamic variations;
@dynamic wormhole;

@end
