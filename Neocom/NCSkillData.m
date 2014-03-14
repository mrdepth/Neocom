//
//  NCSkillData.m
//  Neocom
//
//  Created by Артем Шиманский on 14.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCSkillData.h"
#import "NCCharacterAttributes.h"
#import <objc/runtime.h>

@interface NCSkillData()
@property (nonatomic, strong, readwrite) NSString* skillName;

@end

@implementation NCSkillData

- (NSTimeInterval) trainingTimeToLevelUpWithCharacterAttributes:(NCCharacterAttributes*) attributes {
	return [self skillPointsToLevelUp] / [attributes skillpointsPerSecondForSkill:self];
}

- (NSTimeInterval) trainingTimeToFinishWithCharacterAttributes:(NCCharacterAttributes*) attributes {
	return [self skillPointsToFinish] / [attributes skillpointsPerSecondForSkill:self];
}

- (int32_t) skillPointsToFinish {
	float sp = [self skillPointsAtLevel:self.currentLevel];
	float targetSP = self.targetSkillPoints;
	sp = MAX(sp, self.skillPoints);
	return targetSP > sp ? (targetSP - sp) : 0;
}

- (int32_t) skillPointsToLevelUp {
	float sp = [self skillPointsAtLevel:self.currentLevel];
	float targetSP = [self skillPointsAtLevel:self.currentLevel + 1];
	sp = MAX(sp, self.skillPoints);
	targetSP = MIN(self.targetSkillPoints, targetSP);
	
	return targetSP > sp ? (targetSP - sp) : 0;
}

- (void) setTargetLevel:(int32_t)targetLevel {
	_targetLevel = targetLevel;
	_targetSkillPoints = [self skillPointsAtLevel:targetLevel];
	_trainingTimeToLevelUp = -1.0;
	_trainingTimeToFinish = -1.0;
	objc_setAssociatedObject(self, @"hash", nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void) setCurrentLevel:(int32_t)currentLevel {
	_currentLevel = currentLevel;
	_trainingTimeToLevelUp = -1.0;
	_trainingTimeToFinish = -1.0;
	objc_setAssociatedObject(self, @"hash", nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void) setTrainedLevel:(int32_t)trainedLevel {
	_trainedLevel = trainedLevel;
	objc_setAssociatedObject(self, @"hash", nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void) setSkillPoints:(int32_t)skillPoints {
	_skillPoints = skillPoints;
	_trainingTimeToLevelUp = -1.0;
	_trainingTimeToFinish = -1.0;
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
	_trainingTimeToLevelUp = -1.0;
	_trainingTimeToLevelUp = -1.0;
	_trainingTimeToFinish = -1.0;
}

- (NSTimeInterval) trainingTimeToLevelUp {
	if (_trainingTimeToLevelUp < 0.0) {
		if (!_characterAttributes)
			_trainingTimeToLevelUp = [self trainingTimeToLevelUpWithCharacterAttributes:[NCCharacterAttributes defaultCharacterAttributes]];
		else
			_trainingTimeToLevelUp = [self trainingTimeToLevelUpWithCharacterAttributes:self.characterAttributes];
	}
	return _trainingTimeToLevelUp;
}

- (NSTimeInterval) trainingTime {
	if (_trainingTimeToFinish < 0.0) {
		if (!_characterAttributes)
			_trainingTimeToFinish = [self trainingTimeToFinishWithCharacterAttributes:[NCCharacterAttributes defaultCharacterAttributes]];
		else
			_trainingTimeToFinish = [self trainingTimeToFinishWithCharacterAttributes:self.characterAttributes];
	}
	return _trainingTimeToFinish;
}

- (BOOL) isEqual:(id)object {
	return [object isKindOfClass:[self class]] && self.hash == [object hash];
}

- (NSUInteger) hash {
	NSNumber* hash = objc_getAssociatedObject(self, @"hash");
	if (!hash) {
		NSInteger data[] = {self.typeID, self.targetLevel, self.currentLevel, self.trainedLevel, self.skillPoints};
		NSUInteger hash = [[NSData dataWithBytes:data length:sizeof(data)] hash];
		objc_setAssociatedObject(self, @"hash", @(hash), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
		return hash;
	}
	else
		return [hash unsignedIntegerValue];
}

#pragma mark - NSCoding

- (void) encodeWithCoder:(NSCoder *)aCoder {
	[aCoder encodeInt32:self.typeID forKey:@"typeID"];
	[aCoder encodeInt32:self.skillPoints forKey:@"skillPoints"];
	[aCoder encodeInt32:self.currentLevel forKey:@"currentLevel"];
	[aCoder encodeInt32:self.targetLevel forKey:@"targetLevel"];
	[aCoder encodeInt32:self.trainedLevel forKey:@"trainedLevel"];
	[aCoder encodeBool:self.active forKey:@"active"];
	if (self.characterAttributes)
		[aCoder encodeObject:self.characterAttributes forKey:@"characterAttributes"];
}

- (id) initWithCoder:(NSCoder *)aDecoder {
	int32_t typeID = [aDecoder decodeInt32ForKey:@"typeID"];
	if (self = [super initWithTypeID:typeID error:nil]) {
		self.skillPoints = [aDecoder decodeInt32ForKey:@"skillPoints"];
		self.currentLevel = [aDecoder decodeInt32ForKey:@"currentLevel"];
		self.targetLevel = [aDecoder decodeInt32ForKey:@"targetLevel"];
		self.trainedLevel = [aDecoder decodeInt32ForKey:@"trainedLevel"];
		self.active = [aDecoder decodeBoolForKey:@"active"];
		self.characterAttributes = [aDecoder decodeObjectForKey:@"characterAttributes"];
	}
	return self;
}

@end
