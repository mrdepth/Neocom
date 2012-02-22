//
//  SkillTree.h
//  EVEUniverse
//
//  Created by Artem Shimanski on 1/23/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EVEDBAPI.h"

typedef enum {
	SkillTreeItemAvailabilityUnavailable,
	SkillTreeItemAvailabilityLearned,
	SkillTreeItemAvailabilityNotLearned,
	SkillTreeItemAvailabilityLowLevel
} SkillTreeItemAvailability;

@class EVEAccount;
@class EVEDBInvType;
@interface SkillTreeItem : EVEDBInvType {
	NSInteger skillLevel;
	NSInteger hierarchyLevel;
	SkillTreeItemAvailability skillAvailability;
}
@property (nonatomic) NSInteger skillLevel;
@property (nonatomic) NSInteger hierarchyLevel;
@property (nonatomic) SkillTreeItemAvailability skillAvailability;
- (NSString*) romanSkillLevel;
@end


@interface SkillTree : NSObject {
	NSMutableArray *skills;
@private
	NSDictionary *characterSkills;
	NSArray *skillRequirementsMap;
}

@property (nonatomic, retain) NSArray *skills;

+ (id) skillTreeWithRootSkill: (EVEDBInvType*) skill skillLevel:(NSInteger) skillLevel;
- (id) initWithRootSkill: (EVEDBInvType*) skill skillLevel:(NSInteger) skillLevel;
@end
