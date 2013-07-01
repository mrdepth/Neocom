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

@implementation SkillTreeItem

- (NSString*) romanSkillLevel {
	switch (self.skillLevel) {
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

@interface SkillTree()
@property (nonatomic, strong) NSDictionary *characterSkills;
@property (nonatomic, strong) NSArray *skillRequirementsMap;

- (void) addSkill:(SkillTreeItem*) skill;
- (SkillTreeItemAvailability) skillAvailability:(SkillTreeItem*) skill;

@end


@implementation SkillTree


+ (id) skillTreeWithRootSkill: (EVEDBInvType*) skill skillLevel:(NSInteger) skillLevel {
	return [[SkillTree alloc] initWithRootSkill:skill skillLevel:skillLevel];
}
													  
- (id) initWithRootSkill: (EVEDBInvType*) skill skillLevel:(NSInteger) skillLevel {
	if (self = [super init]) {
		EVEAccount *account = [EVEAccount currentAccount];
		if (account.characterSheet.skills) {
			self.characterSkills = [NSMutableDictionary dictionary];
			for (EVECharacterSheetSkill *skill in account.characterSheet.skills) {
				[self.characterSkills setValue:skill forKey:[NSString stringWithFormat:@"%d", skill.typeID]];
			}
		}
		else
			self.characterSkills = nil;
		
		self.skillRequirementsMap = [NSArray arrayWithContentsOfURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"skillRequirementsMap" ofType:@"plist"]]];
		
		SkillTreeItem *item = [[SkillTreeItem alloc] initWithTypeID:skill.typeID error:nil];
		item.skillLevel = skillLevel;
		item.hierarchyLevel = 0;
		self.skills = [NSMutableArray array];
		[self addSkill:item];
		
	}
	return self;
}

#pragma mark - Private

- (void) addSkill:(SkillTreeItem*) skill {
	[(NSMutableArray*) self.skills addObject:skill];
	skill.skillAvailability = [self skillAvailability:skill];
	
	for (NSDictionary *requirementMap in self.skillRequirementsMap) {
		EVEDBDgmTypeAttribute *attribute = [skill.attributesDictionary valueForKey:[requirementMap valueForKey:SkillTreeRequirementIDKey]];
		if (attribute) {
			EVEDBDgmTypeAttribute *level = [skill.attributesDictionary valueForKey:[requirementMap valueForKey:SkillTreeSkillLevelIDKey]];
			NSInteger typeID = (NSInteger) attribute.value;
			if (typeID && skill.hierarchyLevel < 6 && typeID != skill.typeID) {
				SkillTreeItem *item = [[SkillTreeItem alloc] initWithTypeID:typeID error:nil];
				item.skillLevel = (NSInteger) level.value;
				item.hierarchyLevel = skill.hierarchyLevel + 1;
				[self addSkill:item];
			}
		}		
	}
}

- (SkillTreeItemAvailability) skillAvailability:(SkillTreeItem*) skill {
	if (self.characterSkills) {
		EVECharacterSheetSkill *characterSkill = [self.characterSkills valueForKey:[NSString stringWithFormat:@"%d", skill.typeID]];
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
