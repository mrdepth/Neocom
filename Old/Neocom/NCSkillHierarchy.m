//
//  NCSkillHierarchy.m
//  Neocom
//
//  Created by Артем Шиманский on 15.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCSkillHierarchy.h"
#import <objc/runtime.h>
#import <EVEAPI/EVEAPI.h>
#import "NCSkillData.h"

@implementation NCSkillHierarchySkill

@end

@interface NCSkillHierarchy()
@property (nonatomic, strong, readwrite) NSMutableArray* skills;

- (void) addRequiredSkill:(NCDBInvType*) skill withLevel:(int32_t) level nestingLevel:(int32_t) nestingLevel characterSheet:(EVECharacterSheet*) characterSheet;
@end

@implementation NCSkillHierarchy

- (id) initWithSkill:(NCDBInvTypeRequiredSkill*) skill characterSheet:(EVECharacterSheet*) characterSheet {
	if (self = [super init]) {
		self.skills = [NSMutableArray new];
		[self addRequiredSkill:skill.skillType withLevel:skill.skillLevel nestingLevel:0 characterSheet:characterSheet];
	}
	return self;
}

- (id) initWithSkillType:(NCDBInvType*) skill level:(int32_t) level characterSheet:(EVECharacterSheet*) characterSheet {
	if (self = [super init]) {
		self.skills = [NSMutableArray new];
		[self addRequiredSkill:skill withLevel:level nestingLevel:0 characterSheet:characterSheet];
	}
	return self;
}


#pragma mark - Private

- (void) addRequiredSkill:(NCDBInvType*) skill withLevel:(int32_t) level nestingLevel:(int32_t) nestingLevel characterSheet:(EVECharacterSheet*) characterSheet {
	NCSkillHierarchySkill* skillData = [[NCSkillHierarchySkill alloc] initWithInvType:skill];
	skillData.targetLevel = level;

	if (characterSheet) {
		EVECharacterSheetSkill* characterSkill = characterSheet.skillsMap[@(skill.typeID)];
		skillData.characterSkill = characterSkill;
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
		[self addRequiredSkill:subSkill.skillType withLevel:subSkill.skillLevel nestingLevel:nestingLevel + 1 characterSheet:characterSheet];
}

@end
