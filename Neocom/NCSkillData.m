//
//  NCSkillData.m
//  Neocom
//
//  Created by Артем Шиманский on 14.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCSkillData.h"
#import "NCCharacterAttributes.h"
#import <EVEAPI/EVEAPI.h>
#import <objc/runtime.h>

@interface NCSkillData()
@property (nonatomic, strong, readwrite) NSString* skillName;
@property (nonatomic, assign) int32_t rank;
@property (nonatomic, assign) int32_t typeID;
@property (nonatomic, assign) int32_t primaryAttributeID;
@property (nonatomic, assign) int32_t secondaryAttributeID;


@end

@implementation NCSkillData

- (NSTimeInterval) trainingTimeToLevelUpWithCharacterAttributes:(NCCharacterAttributes*) attributes {
	return [self skillPointsToLevelUp] / [attributes skillpointsPerSecondWithPrimaryAttribute:self.primaryAttributeID secondaryAttribute:self.secondaryAttributeID];
}

- (NSTimeInterval) trainingTimeToFinishWithCharacterAttributes:(NCCharacterAttributes*) attributes {
	return [self skillPointsToFinish] / [attributes skillpointsPerSecondWithPrimaryAttribute:self.primaryAttributeID secondaryAttribute:self.secondaryAttributeID];
}

- (id) initWithInvType:(NCDBInvType*) type {
	if (!type)
		return nil;

	if (self = [super init]) {
		self.type = type;
		[type.managedObjectContext performBlockAndWait:^{
			self.typeID = type.typeID;
			self.rank = [type.attributesDictionary[@(NCSkillTimeConstantAttributeID)] intValue];
			self.primaryAttributeID = [type.attributesDictionary[@(NCPrimaryAttributeAttribteID)] intValue];
			self.secondaryAttributeID = [type.attributesDictionary[@(NCSecondaryAttributeAttribteID)] intValue];
		}];
	}
	return self;
}

- (id) initWithTypeID:(int32_t) typeID {
	__block id obj = self;
	[[[NCDatabase sharedDatabase] managedObjectContext] performBlockAndWait:^{
		if ((obj = [obj initWithInvType:[NCDBInvType invTypeWithTypeID:typeID]])) {
		}
	}];
	self = obj;
	return self;
}


- (float) skillPointsAtLevel:(int32_t) level {
	if (level == 0)
		return 0;
	if (self.rank) {
		float sp = pow(2, 2.5 * level - 2.5) * 250 * self.rank;
		return sp;
	}
	return 0;
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
	_targetSkillPoints = [self skillPointsAtLevel:targetLevel];
	objc_setAssociatedObject(self, @"hash", nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void) setCurrentLevel:(int32_t)currentLevel {
	_currentLevel = currentLevel;
	objc_setAssociatedObject(self, @"hash", nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void) setCharacterSkill:(EVECharacterSheetSkill *)characterSkill {
	_characterSkill = characterSkill;
	objc_setAssociatedObject(self, @"hash", nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (int32_t) trainedLevel {
	return self.characterSkill.level;
}

- (int32_t) skillPoints {
	return self.characterSkill.skillpoints;
}

- (BOOL) isActive {
	if (self.currentLevel == self.targetLevel - 1) {
		for (EVESkillQueueItem* item in self.characterSkill.skillQueueItems) {
			if (item.queuePosition == 0)
				return item.level == self.targetLevel;
		}
	}
	return NO;
}

- (NSString*) skillName {
	if (!_skillName) {
		[self.type.managedObjectContext performBlockAndWait:^{
			_skillName = [NSString stringWithFormat:@"%@ (x%d)", self.type.typeName, self.rank];
		}];
	}
	return _skillName;
}

- (NSTimeInterval) trainingTimeToLevelUp {
	return [self trainingTimeToLevelUpWithCharacterAttributes:self.characterAttributes ?: [NCCharacterAttributes defaultCharacterAttributes]];
}

- (NSTimeInterval) trainingTime {
	return [self trainingTimeToFinishWithCharacterAttributes:self.characterAttributes ?: [NCCharacterAttributes defaultCharacterAttributes]];
}

- (BOOL) isEqual:(id)object {
	return [object isKindOfClass:[self class]] && self.hash == [object hash];
}

- (NSUInteger) hash {
	NSNumber* hash = objc_getAssociatedObject(self, @"hash");
	if (!hash) {
		NSInteger data[] = {self.typeID, self.targetLevel, self.currentLevel, self.trainedLevel};
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
	[aCoder encodeInt32:self.currentLevel forKey:@"currentLevel"];
	[aCoder encodeInt32:self.targetLevel forKey:@"targetLevel"];
	[aCoder encodeObject:self.characterSkill forKey:@"characterSkill"];
	if (self.characterAttributes)
		[aCoder encodeObject:self.characterAttributes forKey:@"characterAttributes"];
}

- (id) initWithCoder:(NSCoder *)aDecoder {
	if (self = [super init]) {
		self.typeID = [aDecoder decodeInt32ForKey:@"typeID"];
		[[[NCDatabase sharedDatabase] managedObjectContext] performBlockAndWait:^{
			self.type = [NCDBInvType invTypeWithTypeID:self.typeID];
			self.rank = [self.type.attributesDictionary[@(NCSkillTimeConstantAttributeID)] intValue];
			self.primaryAttributeID = [self.type.attributesDictionary[@(NCPrimaryAttributeAttribteID)] intValue];
			self.secondaryAttributeID = [self.type.attributesDictionary[@(NCSecondaryAttributeAttribteID)] intValue];
		}];
		self.currentLevel = [aDecoder decodeInt32ForKey:@"currentLevel"];
		self.targetLevel = [aDecoder decodeInt32ForKey:@"targetLevel"];
		self.characterAttributes = [aDecoder decodeObjectForKey:@"characterAttributes"];
		self.characterSkill = [aDecoder decodeObjectForKey:@"characterSkill"];
	}
	return self;
}

@end
