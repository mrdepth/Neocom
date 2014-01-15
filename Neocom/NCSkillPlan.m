//
//  NCSkillPlan.m
//  Neocom
//
//  Created by Artem Shimanski on 17.12.13.
//  Copyright (c) 2013 Artem Shimanski. All rights reserved.
//

#import "NCSkillPlan.h"
#import "NCStorage.h"

@interface NCSkillPlan() {
	NSMutableArray* _skills;
}

@end

@implementation NCSkillPlan

@dynamic attributes;
@dynamic characterID;
@dynamic skillPlanName;
@dynamic skillPlanSkills;

@synthesize trainingTime = _trainingTime;

+ (instancetype) temporarySkillPlanWithAccount:(NCAccount*) account {
	NCSkillPlan* skillPlan = [[self alloc] initWithEntity:[NSEntityDescription entityForName:@"SkillPlan" inManagedObjectContext:[[NCStorage sharedStorage] managedObjectContext]]
						   insertIntoManagedObjectContext:nil];
	return skillPlan;
}

- (void) addRequiredSkillsForType:(EVEDBInvType*) type {
	
}

- (void) addSkill:(EVEDBInvType*) skill withLevel:(NSInteger) level {
	
}

- (void) setSkills:(NSArray *)skills {
	_skills = [[NSMutableArray alloc] initWithArray:skills];
}

- (NSArray*) skills {
	if (!_skills)
		_skills = [NSMutableArray new];
	return _skills;
}

@end
