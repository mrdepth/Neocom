//
//  NCTrainingQueue.m
//  Neocom
//
//  Created by Artem Shimanski on 13.11.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCTrainingQueue.h"
#import "NCCharacter.h"
#import "NCCharacterAttributes.h"
#import "NCDatabase.h"
@import EVEAPI;

@implementation NCTrainingQueueSkill

- (NSTimeInterval) trainingTimeWithCharacterAttributes:(NCCharacterAttributes*) attributes {
	return [self trainingTimeToLevelUpWithCharacterAttributes:attributes];
}

@end

@interface NCTrainingQueue() {
	NSMutableArray<NCTrainingQueueSkill*>* _skills;
}
@property (nonatomic, weak) NSDictionary<NSNumber*, NCSkill*>* characterSkills;
@end

@implementation NCTrainingQueue

- (id) init {
	if (self = [super init]) {
		_skills = [NSMutableArray new];
	}
	return self;
}

- (instancetype) initWithCharacter:(NCCharacter*) character {
	if (self = [self init]) {
		NSMutableDictionary* characterSkills = [NSMutableDictionary new];
		for (NCSkill* skill in character.skills)
			characterSkills[@(skill.typeID)] = skill;
		self.characterSkills = characterSkills;
	}
	return self;
}

- (instancetype) initWithSkillQueue:(EVESkillQueue*) skillQueue {
	if (self = [self init]) {
		[[NCDatabase sharedDatabase] performTaskAndWait:^(NSManagedObjectContext *managedObjectContext) {
			NCFetchedCollection<NCDBInvType*>* invTypes = [NCDBInvType invTypesWithManagedObjectContext:managedObjectContext];
			for (EVESkillQueueItem* item in [skillQueue.skillQueue sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"queuePosition" ascending:YES]]]) {
				[self _addSkill:invTypes[item.typeID] withLevel:item.level];
			}
		}];
	}
	return self;
}

- (void) addRequiredSkillsForType:(NCDBInvType*) type {
	[type.managedObjectContext performBlockAndWait:^{
		[self _addRequiredSkillsForType:type];
	}];
}

- (void) addSkill:(NCDBInvType*) skill withLevel:(int32_t) level {
	[skill.managedObjectContext performBlockAndWait:^{
		[self _addSkill:skill withLevel:level];
	}];
}

- (void) addMastery:(NCDBCertMastery*) mastery {
	[mastery.managedObjectContext performBlockAndWait:^{
		[self _addMastery:mastery];
	}];
}

- (NSIndexSet*) removeSkill:(NCTrainingQueueSkill*) skill {
	return [self _removeSkill:skill];
}

- (void) moveSkillAdIndex:(NSInteger) from toIndex:(NSInteger) to {
	NCTrainingQueueSkill* skill = _skills[from];
	[_skills removeObjectAtIndex:from];
	[_skills insertObject:skill atIndex:to];
}

- (NSTimeInterval) trainingTimeWithCharacterAttributes:(NCCharacterAttributes*) characterAttributes {
	__block NSTimeInterval trainingTime = 0;
	for (NCTrainingQueueSkill *skill in self.skills) {
		trainingTime += [skill trainingTimeWithCharacterAttributes:characterAttributes];
	}
	return trainingTime;
}

#pragma mark - Private

- (void) _addRequiredSkillsForType:(NCDBInvType*) type {
	for (NCDBInvTypeRequiredSkill* skill in type.requiredSkills)
		[self _addSkill:skill.skillType withLevel:skill.skillLevel];
}

- (void) _addSkill:(NCDBInvType*) skill withLevel:(int32_t) level {
	NCSkill *characterSkill = self.characterSkills[@(skill.typeID)];
	if (characterSkill.level >= level)
		return;
	
	BOOL addedDependence = NO;
	for (int32_t skillLevel = characterSkill.level + 1; skillLevel <= level; skillLevel++) {
		BOOL isExist = NO;
		for (NCTrainingQueueSkill* item in self.skills) {
			if (item.typeID == skill.typeID && item.targetLevel == skillLevel) {
				isExist = YES;
				break;
			}
		}
		if (!isExist) {
			if (!addedDependence) {
				[self _addRequiredSkillsForType:skill];
				addedDependence = YES;
			}
			NCTrainingQueueSkill* item = [[NCTrainingQueueSkill alloc] initWithInvType:skill];
			item.level = skillLevel - 1;
			item.targetLevel = skillLevel;
			if (item.level == characterSkill.level)
				item.trainingStartDate = characterSkill.trainingStartDate;
			[_skills addObject:item];
		}
	}
}

- (NSIndexSet*) _removeSkill:(NCTrainingQueueSkill*) skill {
	int32_t typeID = skill.typeID;
	NSInteger level = skill.targetLevel;
	NSInteger index = 0;
	NSMutableIndexSet* indexes = [NSMutableIndexSet indexSet];
	for (NCTrainingQueueSkill* item in self.skills) {
		if (item.typeID == typeID && item.targetLevel >= level)
			[indexes addIndex:index];
		index++;
	}
	[_skills removeObjectsAtIndexes:indexes];
	return indexes;
}

- (void) _addMastery:(NCDBCertMastery*) mastery {
	for (NCDBCertSkill* skill in mastery.skills) {
		[self _addSkill:skill.type withLevel:skill.skillLevel];
	}
}

@end
