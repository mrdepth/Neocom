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

- (void) addRequiredSkill:(NCDBInvType*) skill withLevel:(int32_t) level nestingLevel:(int32_t) nestingLevel account:(NCAccount*) account;
@end

@implementation NCSkillHierarchy

- (id) initWithSkill:(NCDBInvTypeRequiredSkill*) skill account:(NCAccount*) account {
	if (self = [super init]) {
		self.skills = [NSMutableArray new];
		[self addRequiredSkill:skill.skillType withLevel:skill.skillLevel nestingLevel:0 account:account];
	}
	return self;
}

- (id) initWithSkillType:(NCDBInvType*) skill level:(int32_t) level account:(NCAccount*) account {
	if (self = [super init]) {
		self.skills = [NSMutableArray new];
		[self addRequiredSkill:skill withLevel:level nestingLevel:0 account:account];
	}
	return self;
}


#pragma mark - Private

- (void) addRequiredSkill:(NCDBInvType*) skill withLevel:(int32_t) level nestingLevel:(int32_t) nestingLevel account:(NCAccount*) account {
	NCSkillHierarchySkill* skillData = [[NCSkillHierarchySkill alloc] initWithInvType:skill];
	skillData.targetLevel = level;

	if (account.characterSheet) {
		EVECharacterSheetSkill* characterSkill = account.characterSheet.skillsMap[@(skill.typeID)];
		skillData.currentLevel = characterSkill.level;
		skillData.skillPoints = characterSkill.skillpoints;
		if (!characterSkill)
			skillData.availability = NCSkillHierarchyAvailabilityNotLearned;
		else if (characterSkill.level < skillData.targetLevel)
			skillData.availability = NCSkillHierarchyAvailabilityLowLevel;
		else
			skillData.availability = NCSkillHierarchyAvailabilityLearned;
	}
	else
		skillData.availability = NCSkillHierarchyAvailabilityUnavailable;

	skillData.nestingLevel = nestingLevel;
	[(NSMutableArray*) self.skills addObject:skillData];
	for (NCDBInvTypeRequiredSkill* subSkill in skill.requiredSkills)
		[self addRequiredSkill:subSkill.skillType withLevel:subSkill.skillLevel nestingLevel:nestingLevel + 1 account:account];
}

@end
