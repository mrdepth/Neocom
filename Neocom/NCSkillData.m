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
#import <objc/runtime.h>
#import "murmurhash3.h"

@interface NCSkillData()
@property (nonatomic, strong, readwrite) NSString* skillName;

@end

@implementation NCSkillData

- (NSTimeInterval) trainingTimeToLevelUpWithCharacterAttributes:(NCCharacterAttributes*) attributes {
	float sp = [self skillPointsAtLevel:self.currentLevel];
	float targetSP = [self skillPointsAtLevel:self.currentLevel + 1];
	sp = MAX(sp, self.skillPoints);
	targetSP = MIN(self.targetSkillPoints, targetSP);

	return targetSP > sp ? (targetSP - sp) / [attributes skillpointsPerSecondForSkill:self] : 0.0;
}

- (NSTimeInterval) trainingTimeToFinishWithCharacterAttributes:(NCCharacterAttributes*) attributes {
	float sp = [self skillPointsAtLevel:self.currentLevel];
	float targetSP = self.targetSkillPoints;
	sp = MAX(sp, self.skillPoints);
	
	return targetSP > sp ? (targetSP - sp) / [attributes skillpointsPerSecondForSkill:self] : 0.0;
}

- (void) setTargetLevel:(NSInteger)targetLevel {
	_targetLevel = targetLevel;
	_targetSkillPoints = [self skillPointsAtLevel:targetLevel];
	_trainingTimeToLevelUp = -1.0;
	_trainingTimeToFinish = -1.0;
	objc_setAssociatedObject(self, @"hash", nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void) setCurrentLevel:(NSInteger)currentLevel {
	_currentLevel = currentLevel;
	_trainingTimeToLevelUp = -1.0;
	_trainingTimeToFinish = -1.0;
	objc_setAssociatedObject(self, @"hash", nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void) setTrainedLevel:(NSInteger)trainedLevel {
	_trainedLevel = trainedLevel;
	objc_setAssociatedObject(self, @"hash", nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void) setSkillPoints:(NSInteger)skillPoints {
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
		NSUInteger hash = murmurHash3(data, sizeof(data), (uint32_t)[self class]);
		objc_setAssociatedObject(self, @"hash", @(hash), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
		return hash;
	}
	else
		return [hash unsignedIntegerValue];
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
