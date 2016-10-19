//
//  NCSkillPlan+CoreDataProperties.m
//  Develop
//
//  Created by Artem Shimanski on 18.10.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCSkillPlan+CoreDataProperties.h"

@implementation NCSkillPlan (CoreDataProperties)

+ (NSFetchRequest<NCSkillPlan *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"SkillPlan"];
}

@dynamic active;
@dynamic name;
@dynamic skills;
@dynamic account;

@end
