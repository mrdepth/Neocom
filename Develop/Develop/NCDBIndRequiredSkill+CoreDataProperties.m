//
//  NCDBIndRequiredSkill+CoreDataProperties.m
//  Develop
//
//  Created by Artem Shimanski on 20.10.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCDBIndRequiredSkill+CoreDataProperties.h"

@implementation NCDBIndRequiredSkill (CoreDataProperties)

+ (NSFetchRequest<NCDBIndRequiredSkill *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"IndRequiredSkill"];
}

@dynamic skillLevel;
@dynamic activity;
@dynamic skillType;

@end
