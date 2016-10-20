//
//  NCDBEveIcon+CoreDataProperties.m
//  Develop
//
//  Created by Artem Shimanski on 20.10.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCDBEveIcon+CoreDataProperties.h"

@implementation NCDBEveIcon (CoreDataProperties)

+ (NSFetchRequest<NCDBEveIcon *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"EveIcon"];
}

@dynamic iconFile;
@dynamic activities;
@dynamic attributeTypes;
@dynamic categories;
@dynamic groups;
@dynamic image;
@dynamic itemGroups;
@dynamic marketGroups;
@dynamic masteryLevels;
@dynamic metaGroups;
@dynamic npcGroups;
@dynamic races;
@dynamic types;

@end
