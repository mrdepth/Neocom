//
//  NCSkillPlan.m
//  Neocom
//
//  Created by Artem Shimanski on 17.12.13.
//  Copyright (c) 2013 Artem Shimanski. All rights reserved.
//

#import "NCSkillPlan.h"
#import "NCStorage.h"

#define NCSkillPlanTypeIDKey @"typeID"
#define NCSkillPlanTargetLevelKey @"targetLevel"

@interface NCSkillPlan() {
	NSMutableArray* _skills;
}

- (void) reload;

@end

@implementation NCSkillPlan

@dynamic active;
@dynamic skillPlanName;
@dynamic skills;
@dynamic account;

@synthesize trainingQueue = _trainingQueue;

- (NCTrainingQueue*) trainingQueue {
	if (!_trainingQueue) {
		if (!self.account)
			return nil;
		[self reload];
	}
	return _trainingQueue;
}

- (void) setTrainingQueue:(NCTrainingQueue *)trainingQueue {
	[self willChangeValueForKey:@"trainingQueue"];
	_trainingQueue = trainingQueue;
	[self updateSkillPoints];
	[self didChangeValueForKey:@"trainingQueue"];
}

- (void) save {
	NSMutableArray* skills = [NSMutableArray new];
	for (NCSkillData* skill in self.trainingQueue.skills) {
		NSDictionary* item = @{NCSkillPlanTypeIDKey: @(skill.typeID), NCSkillPlanTargetLevelKey: @(skill.targetLevel)};
		[skills addObject:item];
	}
	
	[[[NCStorage sharedStorage] managedObjectContext] performBlockAndWait:^{
		self.skills = skills;
		[[NCStorage sharedStorage] saveContext];
	}];
}

- (void) mergeWithTrainingQueue:(NCTrainingQueue*) trainingQueue {
	NCTrainingQueue* newTrainingQueue = [self.trainingQueue copy];
	for (NCSkillData* skillData in trainingQueue.skills)
		[newTrainingQueue addSkill:skillData withLevel:skillData.targetLevel];
	self.trainingQueue = newTrainingQueue;
	[self save];
}

- (void) removeSkill:(NCSkillData *)skill {
	NCTrainingQueue* newTrainingQueue = [self.trainingQueue copy];
	[newTrainingQueue removeSkill:skill];
	self.trainingQueue = newTrainingQueue;
	[self save];
}

- (void) updateSkillPoints {
	/*NCTrainingQueue* newTrainingQueue = [[NCTrainingQueue alloc] initWithAccount:self.account];
	for (NCSkillData* skillData in self.trainingQueue.skills)
		[newTrainingQueue addSkill:skillData withLevel:skillData.targetLevel];
	self.trainingQueue = newTrainingQueue;*/
	[self.trainingQueue updateSkillPointsFromAccount:self.account];
}

- (void) reloadIfNeeded {
	if (_trainingQueue)
		[self reload];
}

#pragma mark - Private

- (void) reload {
	NCTrainingQueue* trainingQueue = [[NCTrainingQueue alloc] initWithAccount:self.account];
	for (NSDictionary* item in self.skills) {
		NSInteger typeID = [item[NCSkillPlanTypeIDKey] integerValue];
		NSInteger targetLevel = [item[NCSkillPlanTargetLevelKey] integerValue];
		EVEDBInvType* type = [EVEDBInvType invTypeWithTypeID:typeID error:nil];
		if (type)
			[trainingQueue addSkill:type withLevel:targetLevel];
	}
	self.trainingQueue = trainingQueue;
}


@end
