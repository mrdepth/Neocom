//
//  SkillTree.m
//  EVEUniverse
//
//  Created by Artem Shimanski on 1/23/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "SkillTree.h"
#import "Globals.h"
#import "EVEAccount.h"
#import "EVEOnlineAPI.h"

@implementation SkillTreeItem : EVEDBInvType
@synthesize skillLevel;
@synthesize hierarchyLevel;
@synthesize skillAvailability;

- (NSString*) romanSkillLevel {
	switch (skillLevel) {
		case 1:
			return @"I";
		case 2:
			return @"II";
		case 3:
			return @"III";
		case 4:
			return @"IV";
		case 5:
			return @"V";
		default:
			return @"";
	}
}

@end

@interface SkillTree(Private)

- (void) addSkill:(SkillTreeItem*) skill;
- (SkillTreeItemAvailability) skillAvailability:(SkillTreeItem*) skill;

@end


@implementation SkillTree
@synthesize skills;


+ (id) skillTreeWithRootSkill: (EVEDBInvType*) skill skillLevel:(NSInteger) skillLevel {
	return [[[SkillTree alloc] initWithRootSkill:skill skillLevel:skillLevel] autorelease];
}
													  
- (id) initWithRootSkill: (EVEDBInvType*) skill skillLevel:(NSInteger) skillLevel {
	if (self = [super init]) {
		EVEAccount *account = [EVEAccount currentAccount];
		if (account.characterSheet.skills) {
			characterSkills = [NSMutableDictionary dictionary];
			for (EVECharacterSheetSkill *skill in account.characterSheet.skills) {
				[characterSkills setValue:skill forKey:[NSString stringWithFormat:@"%d", skill.typeID]];
			}
		}
		else
			characterSkills = nil;
		
		skillRequirementsMap = [NSArray arrayWithContentsOfURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"skillRequirementsMap" ofType:@"plist"]]];
		
		SkillTreeItem *item = [[[SkillTreeItem alloc] initWithTypeID:skill.typeID error:nil] autorelease];
		item.skillLevel = skillLevel;
		item.hierarchyLevel = 0;
		self.skills = [NSMutableArray array];
		[self addSkill:item];
		
	}
	return self;
}

- (void) dealloc {
	[skills release];
	[super dealloc];
}

@end

@implementation SkillTree(Private)

- (void) addSkill:(SkillTreeItem*) skill {
	[skills addObject:skill];
	skill.skillAvailability = [self skillAvailability:skill];
	
	for (NSDictionary *requirementMap in skillRequirementsMap) {
		EVEDBDgmTypeAttribute *attribute = [skill.attributesDictionary valueForKey:[requirementMap valueForKey:SkillTreeRequirementIDKey]];
		if (attribute) {
			EVEDBDgmTypeAttribute *level = [skill.attributesDictionary valueForKey:[requirementMap valueForKey:SkillTreeSkillLevelIDKey]];
			NSInteger typeID = (NSInteger) attribute.value;
			if (typeID && skill.hierarchyLevel < 6 && typeID != skill.typeID) {
				SkillTreeItem *item = [[[SkillTreeItem alloc] initWithTypeID:typeID error:nil] autorelease];
				item.skillLevel = (NSInteger) level.value;
				item.hierarchyLevel = skill.hierarchyLevel + 1;
				[self addSkill:item];
			}
		}		
	}
}

- (SkillTreeItemAvailability) skillAvailability:(SkillTreeItem*) skill {
	if (characterSkills) {
		EVECharacterSheetSkill *characterSkill = [characterSkills valueForKey:[NSString stringWithFormat:@"%d", skill.typeID]];
		if (!characterSkill)
			return SkillTreeItemAvailabilityNotLearned;
		else if (characterSkill.level < skill.skillLevel)
			return SkillTreeItemAvailabilityLowLevel;
		else
			return SkillTreeItemAvailabilityLearned;
	}
	else
		return SkillTreeItemAvailabilityUnavailable;
}

@end
