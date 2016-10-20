//
//  NCDBInvTypeRequiredSkill+CoreDataProperties.m
//  Develop
//
//  Created by Artem Shimanski on 20.10.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCDBInvTypeRequiredSkill+CoreDataProperties.h"

@implementation NCDBInvTypeRequiredSkill (CoreDataProperties)

+ (NSFetchRequest<NCDBInvTypeRequiredSkill *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"InvTypeRequiredSkill"];
}

@dynamic skillLevel;
@dynamic skillType;
@dynamic type;

@end
