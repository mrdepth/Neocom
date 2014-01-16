//
//  NCSkillHierarchy.m
//  Neocom
//
//  Created by Артем Шиманский on 15.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCSkillHierarchy.h"
#import <objc/runtime.h>
#import "NCAccount.h"
#import "NCSkillData.h"

@implementation NCSkillHierarchySkill

@end

@interface NCSkillHierarchy()
@property (nonatomic, strong, readwrite) NSMutableArray* skills;

- (void) addRequiredSkill:(EVEDBInvTypeRequiredSkill*) skill withNestingLevel:(NSInteger) level account:(NCAccount*) account;
@end

@implementation NCSkillHierarchy

- (id) initWithSkill:(EVEDBInvType*) skill level:(NSInteger) level account:(NCAccount*) account {
	if (self = [super init]) {
		EVEDBInvTypeRequiredSkill* requiredSkill = [EVEDBInvTypeRequiredSkill invTypeWithInvType:skill];
		requiredSkill.requiredLevel = level;
		self.skills = [NSMutableArray new];
		[self addRequiredSkill:requiredSkill withNestingLevel:0 account:account];
	}
	return self;
}

#pragma mark - Private

- (void) addRequiredSkill:(EVEDBInvTypeRequiredSkill*) skill withNestingLevel:(NSInteger) level account:(NCAccount*) account {
	NCSkillHierarchySkill* skillData = [[NCSkillHierarchySkill alloc] initWithInvType:skill];
	skillData.targetLevel = skill.requiredLevel;

	if (account.characterSheet) {
		EVECharacterSheetSkill* characterSkill = account.characterSheet.skillsMap[@(skill.typeID)];
		skillData.currentLevel = characterSkill.level;
		skillData.skillPoints = characterSkill.skillpoints;
		if (!characterSkill)
			skillData.availability = NCSkillHierarchyAvailabilityNotLearned;
		else if (characterSkill.level < level)
			skillData.availability = NCSkillHierarchyAvailabilityLowLevel;
		else
			skillData.availability = NCSkillHierarchyAvailabilityLearned;
	}
	else
		skillData.availability = NCSkillHierarchyAvailabilityUnavailable;

	skillData.nestingLevel = level;
	[(NSMutableArray*) self.skills addObject:skillData];
	for (EVEDBInvTypeRequiredSkill* subSkill in skill.requiredSkills)
		[self addRequiredSkill:subSkill withNestingLevel:level + 1 account:account];
}

@end
