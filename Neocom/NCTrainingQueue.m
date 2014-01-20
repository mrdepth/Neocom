//
//  NCTrainingQueue.m
//  Neocom
//
//  Created by Артем Шиманский on 15.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCTrainingQueue.h"
#import "EVEOnlineAPI.h"
#import "NCAccount.h"
//#import "NCCharacterAttributes.h"

@interface NCTrainingQueue() {
	NSMutableArray* _skills;
}
@property (nonatomic, strong) NSDictionary* characterSkills;
@property (nonatomic, strong) NCCharacterAttributes* attributes;

@end

@implementation NCTrainingQueue
@synthesize trainingTime = _trainingTime;

- (id) init {
	if (self = [super init]) {
		self.attributes = [NCCharacterAttributes defaultCharacterAttributes];
		_skills = [NSMutableArray new];
	}
	return self;
}

- (id) initWithAccount:(NCAccount*) account {
	if (self = [super init]) {
		if (account) {
			self.characterSkills = account.characterSheet.skillsMap;
			self.attributes = account.characterAttributes;
		}
		else
			self.attributes = [NCCharacterAttributes defaultCharacterAttributes];
		_skills = [NSMutableArray new];
	}
	return self;
}

- (void) setSkills:(NSArray *)skills {
	_skills = [[NSMutableArray alloc] initWithArray:skills];
	_trainingTime = -1;
}

- (void) addRequiredSkillsForType:(EVEDBInvType*) type {
	for (EVEDBInvTypeRequiredSkill* skill in type.requiredSkills)
		[self addSkill:skill withLevel:skill.requiredLevel];
}

- (void) addSkill:(EVEDBInvType*) skill withLevel:(NSInteger) level {
	EVECharacterSheetSkill *characterSkill = self.characterSkills[@(skill.typeID)];
	if (characterSkill.level >= level)
		return;
	
	BOOL addedDependence = NO;
	for (NSInteger skillLevel = characterSkill.level + 1; skillLevel <= level; skillLevel++) {
		BOOL isExist = NO;
		for (NCSkillData *item in self.skills) {
			if (item.typeID == skill.typeID && item.targetLevel == skillLevel) {
				isExist = YES;
				break;
			}
		}
		if (!isExist) {
			if (!addedDependence) {
				[self addRequiredSkillsForType:skill];
				addedDependence = YES;
			}
			NCSkillData* skillData = [NCSkillData invTypeWithInvType:skill];
			skillData.targetLevel = skillLevel;
			skillData.currentLevel = skillLevel - 1;
			skillData.trainedLevel = characterSkill.level;
			
			skillData.skillPoints = characterSkill.skillpoints;
			[_skills addObject:skillData];
		}
	}
	_trainingTime = -1;
}

- (NSTimeInterval) trainingTime {
	if (_trainingTime < 0) {
		_trainingTime = 0;
		
		for (NCSkillData *skill in self.skills) {
			if (skill.currentLevel < skill.targetLevel)
				_trainingTime += [skill trainingTimeWithCharacterAttributes:self.attributes];
		}
	}
	return _trainingTime;
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone {
	NCTrainingQueue* trainingQueue = [[self.class allocWithZone:zone] init];
	trainingQueue.characterSkills = self.characterSkills;
	trainingQueue.attributes = self.attributes;
	
	trainingQueue.skills = self.skills;
	return trainingQueue;
}

@end
