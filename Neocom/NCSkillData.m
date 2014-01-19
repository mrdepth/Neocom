//
//  NCSkillData.m
//  Neocom
//
//  Created by Артем Шиманский on 14.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCSkillData.h"
#import "NCCharacterAttributes.h"
#import "EVEDBInvType+Neocom.h"

@interface NCSkillData()
@property (nonatomic, strong, readwrite) NSString* skillName;

@end

@implementation NCSkillData

- (NSTimeInterval) trainingTimeWithCharacterAttributes:(NCCharacterAttributes*) attributes {
	float sp = [self skillPointsAtLevel:self.currentLevel];
	float targetSP = [self skillPointsAtLevel:self.currentLevel + 1];
	sp = MAX(sp, self.skillPoints);
	targetSP = MIN(self.targetSkillPoints, targetSP);

	return targetSP > sp ? (targetSP - sp) / [attributes skillpointsPerSecondForSkill:self] : 0.0;
}

- (void) setTargetLevel:(NSInteger)targetLevel {
	_targetLevel = targetLevel;
	_targetSkillPoints = [self skillPointsAtLevel:targetLevel];
	_trainingTime = -1.0;
}

- (void) setCurrentLevel:(NSInteger)currentLevel {
	_currentLevel = currentLevel;
	_trainingTime = -1.0;
}

- (void) setSkillPoints:(NSInteger)skillPoints {
	_skillPoints = skillPoints;
	_trainingTime = -1.0;
}

- (NSString*) skillName {
	if (!_skillName) {
		EVEDBDgmTypeAttribute *attribute = self.attributesDictionary[@(275)];
		_skillName = [NSString stringWithFormat:@"%@ (x%d)", self.typeName, (int) attribute.value];
	}
	return _skillName;
}

- (void) setCharacterAttributes:(NCCharacterAttributes *)characterAttributes {
	_characterAttributes = characterAttributes;
	_trainingTime = -1.0;
}

- (NSTimeInterval) trainingTime {
	if (_trainingTime < 0.0) {
		if (!_characterAttributes)
			_trainingTime = [self trainingTimeWithCharacterAttributes:[NCCharacterAttributes defaultCharacterAttributes]];
		else
			_trainingTime = [self trainingTimeWithCharacterAttributes:self.characterAttributes];
	}
	return _trainingTime;
}

#pragma mark - NSCoding

- (void) encodeWithCoder:(NSCoder *)aCoder {
	[aCoder encodeInteger:self.typeID forKey:@"typeID"];
	[aCoder encodeInteger:self.skillPoints forKey:@"skillPoints"];
	[aCoder encodeInteger:self.currentLevel forKey:@"currentLevel"];
	[aCoder encodeInteger:self.targetLevel forKey:@"targetLevel"];
	[aCoder encodeInteger:self.trainedLevel forKey:@"trainedLevel"];
	[aCoder encodeBool:self.active forKey:@"active"];
	if (self.characterAttributes)
		[aCoder encodeObject:self.characterAttributes forKey:@"characterAttributes"];
}

- (id) initWithCoder:(NSCoder *)aDecoder {
	NSInteger typeID = [aDecoder decodeIntegerForKey:@"typeID"];
	if (self = [super initWithTypeID:typeID error:nil]) {
		self.skillPoints = [aDecoder decodeIntegerForKey:@"skillPoints"];
		self.currentLevel = [aDecoder decodeIntegerForKey:@"currentLevel"];
		self.targetLevel = [aDecoder decodeIntegerForKey:@"targetLevel"];
		self.trainedLevel = [aDecoder decodeIntegerForKey:@"trainedLevel"];
		self.active = [aDecoder decodeBoolForKey:@"active"];
		self.characterAttributes = [aDecoder decodeObjectForKey:@"characterAttributes"];
	}
	return self;
}

@end
