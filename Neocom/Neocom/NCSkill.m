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
			NCFetchedCollection<NCDBDgmTypeAttribute*>* attributes = type.attributesMap;
			self.typeID = type.typeID;
			self.rank = attributes[NCSkillTimeConstantAttributeID].value;
			self.primaryAttributeID = attributes[NCPrimaryAttributeAttribteID].value;
			self.secondaryAttributeID = attributes[NCSecondaryAttributeAttribteID].value;
			self.typeName = type.typeName;
		}];
		if (!self.rank || self.primaryAttributeID || !self.secondaryAttributeID)
			self = nil;
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

- (int32_t) skillPoints {
	return self.startSkillPoints;
}

- (NSTimeInterval) trainingTimeToLevel:(int32_t) level withCharacterAttributes:(NCCharacterAttributes*) attributes {
	if (level > self.level)
		return ([self skillPointsAtLevel:level] - self.skillPoints) / [attributes skillpointsPerSecondWithPrimaryAttribute:self.primaryAttributeID secondaryAttribute:self.secondaryAttributeID];
	else
		return 0;
}

- (NSTimeInterval) trainingTimeToLevelUpWithCharacterAttributes:(NCCharacterAttributes*) attributes {
	if (self.level < 5)
		return [self trainingTimeToLevel:self.level + 1 withCharacterAttributes:attributes];
	else
		return 0;
}

@end
