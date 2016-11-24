//
//  NCSkill.m
//  Neocom
//
//  Created by Artem Shimanski on 12.11.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCSkill.h"
#import "NCCharacterAttributes.h"
#import "NCDatabase.h"
@import EVEAPI;

@interface NCSkill()
@property (nonatomic, assign, readwrite) int32_t typeID;
@property (nonatomic, copy, readwrite) NSString* typeName;
@property (nonatomic, assign, readwrite) int32_t primaryAttributeID;
@property (nonatomic, assign, readwrite) int32_t secondaryAttributeID;
@property (nonatomic, assign, readwrite) int32_t rank;


@end

@implementation NCSkill

- (id) initWithInvType:(NCDBInvType*) type {
	if (!type)
		return nil;
	
	if (self = [super init]) {
		[type.managedObjectContext performBlockAndWait:^{
			NCFetchedCollection<NCDBDgmTypeAttribute*>* attributes = type.allAttributes;
			self.typeID = type.typeID;
			self.rank = attributes[NCSkillTimeConstantAttributeID].value;
			self.primaryAttributeID = attributes[NCPrimaryAttributeAttribteID].value;
			self.secondaryAttributeID = attributes[NCSecondaryAttributeAttribteID].value;
			self.typeName = type.typeName;
		}];
		if (!self.rank || !self.primaryAttributeID || !self.secondaryAttributeID)
			self = nil;
	}
	return self;
}

- (id) initWithInvType:(NCDBInvType*) type skill:(EVESkillQueueItem*) skill inQueue:(EVESkillQueue*) skillQueue {
	if (self = [self initWithInvType:type]) {
		self.level = skill.level - 1;
		self.startSkillPoints = skill.startSP;
		self.trainingStartDate = [skillQueue.eveapi localTimeWithServerTime:skill.startTime];
		self.trainingEndDate = [skillQueue.eveapi localTimeWithServerTime:skill.endTime];

	}
	return self;
}

- (id) initWithSkill:(EVESkillQueueItem*) skill inQueue:(EVESkillQueue*) skillQueue {
	if (self = [super init]) {
		self.typeID = skill.typeID;
		self.rank = [self rankWithSkillPoints:skill.endSP atLevel:skill.level];
		self.level = skill.level - 1;
		self.startSkillPoints = skill.startSP;
		self.trainingStartDate = [skillQueue.eveapi localTimeWithServerTime:skill.startTime];
		self.trainingEndDate = [skillQueue.eveapi localTimeWithServerTime:skill.endTime];
	}
	return self;
}

- (int32_t) skillPointsAtLevel:(int32_t) level {
	if (level == 0 || self.rank == 0)
		return 0;
	float sp = pow(2, 2.5 * level - 2.5) * 250.0 * self.rank;
	return round(sp);
}

- (int32_t) levelAtSkillPoints:(int32_t) skillpoints {
	if (skillpoints == 0 || self.rank == 0)
		return 0;
	skillpoints += 1; //avoid rounding error
	float level = (log(skillpoints/(250.0 * self.rank)) / log(2.0) + 2.5) / 2.5;
	return trunc(level);
}

- (int32_t) rankWithSkillPoints:(int32_t) skillPoint atLevel:(int32_t) level {
	return round(skillPoint / (pow(2, 2.5 * level - 2.5) * 250.0));
}

- (int32_t) skillPoints {
	if (self.trainingStartDate && self.trainingEndDate) {
		int32_t endSP = [self skillPointsAtLevel:self.level + 1];
		NSTimeInterval t = [self.trainingEndDate timeIntervalSinceDate:self.trainingStartDate];
		if (t > 0) {
			float spps = (endSP - self.startSkillPoints) / t;
			t = [self.trainingEndDate timeIntervalSinceNow];
			float sp = t > 0 ? endSP - t * spps : endSP;
			return MAX(sp, self.startSkillPoints);
		}
		else
			return 0;
	}
	else
		return self.startSkillPoints;
}

- (float) trainingProgress {
	float start = [self skillPointsAtLevel:self.level];
	float end = [self skillPointsAtLevel:self.level + 1];
	float sp = self.skillPoints;
	float progress = (sp - start) / (end - start);
	return progress;
}

- (NSTimeInterval) trainingTimeToLevel:(int32_t) level withCharacterAttributes:(NCCharacterAttributes*) attributes {
	if (!attributes)
		attributes = [NCCharacterAttributes defaultCharacterAttributes];
	return ([self skillPointsAtLevel:level] - self.skillPoints) / [attributes skillpointsPerSecondWithPrimaryAttribute:self.primaryAttributeID secondaryAttribute:self.secondaryAttributeID];
}

- (NSTimeInterval) trainingTimeToLevelUpWithCharacterAttributes:(NCCharacterAttributes*) attributes {
	if (self.level < 5)
		return [self trainingTimeToLevel:self.level + 1 withCharacterAttributes:attributes];
	else
		return 0;
}

@end
