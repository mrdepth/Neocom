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
@property (nonatomic, strong) NCCharacterAttributes* characterAttributes;

@end

@implementation NCTrainingQueue
@synthesize trainingTime = _trainingTime;

- (id) init {
	if (self = [super init]) {
		self.characterAttributes = [NCCharacterAttributes defaultCharacterAttributes];
		_skills = [NSMutableArray new];
	}
	return self;
}

- (id) initWithAccount:(NCAccount*) account {
	if (self = [super init]) {
		if (account) {
			self.characterSkills = account.characterSheet.skillsMap;
			self.characterAttributes = account.characterAttributes;
		}
		else
			self.characterAttributes = [NCCharacterAttributes defaultCharacterAttributes];
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
			skillData.characterAttributes = self.characterAttributes;
			
			skillData.skillPoints = characterSkill.skillpoints;
			[_skills addObject:skillData];
		}
	}
	_trainingTime = -1;
}

- (void) removeSkill:(NCSkillData*) skill {
	NSInteger typeID = skill.typeID;
	NSInteger level = skill.targetLevel;
	NSInteger index = 0;
	NSMutableIndexSet* indexes = [NSMutableIndexSet indexSet];
	for (NCSkillData* skillData in self.skills) {
		if (skillData.typeID == typeID && skillData.targetLevel >= level) {
			_trainingTime -= skillData.trainingTimeToLevelUp;
			[indexes addIndex:index];
		}
		index++;
	}
	[_skills removeObjectsAtIndexes:indexes];
}

- (void) addMastery:(EVEDBCertMastery*) mastery {
	for (EVEDBCertSkill* skill in mastery.certificate.skills[mastery.masteryLevel]) {
		[self addSkill:skill.skill withLevel:skill.skillLevel];
	}
}

- (void) updateSkillPointsFromAccount:(NCAccount*) account {
	EVESkillQueueItem* firstSkill = account.skillQueue.skillQueue.count > 0 ? account.skillQueue.skillQueue[0] : nil;
	for (NCSkillData* skillData in self.skills) {
		EVECharacterSheetSkill* characterSkill = account.characterSheet.skillsMap[@(skillData.typeID)];
		if (characterSkill)
			skillData.skillPoints = characterSkill.skillpoints;
		if (firstSkill)
			skillData.active = skillData.typeID == firstSkill.typeID && skillData.targetLevel == firstSkill.level && skillData.currentLevel == skillData.targetLevel - 1;
	}
	_trainingTime = -1.0;
}

- (NSTimeInterval) trainingTime {
	if (_trainingTime < 0) {
		_trainingTime = 0;
		
		for (NCSkillData *skill in self.skills) {
			if (skill.currentLevel < skill.targetLevel)
				_trainingTime += skill.trainingTimeToLevelUp;
		}
	}
	return _trainingTime;
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone {
	NCTrainingQueue* trainingQueue = [[self.class allocWithZone:zone] init];
	trainingQueue.characterSkills = self.characterSkills;
	trainingQueue.characterAttributes = self.characterAttributes;
	
	trainingQueue.skills = self.skills;
	return trainingQueue;
}

@end
