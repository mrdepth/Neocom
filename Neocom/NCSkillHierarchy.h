//
//  NCSkillHierarchy.h
//  Neocom
//
//  Created by Артем Шиманский on 15.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NCSkillData.h"

typedef NS_ENUM(NSInteger, NCSkillHierarchyAvailability) {
	NCSkillHierarchyAvailabilityUnavailable,
	NCSkillHierarchyAvailabilityLearned,
	NCSkillHierarchyAvailabilityNotLearned,
	NCSkillHierarchyAvailabilityLowLevel
};

@interface NCSkillHierarchySkill: NCSkillData
@property (nonatomic, assign) int32_t nestingLevel;
@property (nonatomic, assign) NCSkillHierarchyAvailability availability;
@end

@class NCAccount;
@interface NCSkillHierarchy : NSObject
@property (nonatomic, strong, readonly) NSArray* skills;

- (id) initWithSkill:(NCDBInvTypeRequiredSkill*) skill account:(NCAccount*) account;
- (id) initWithSkillType:(NCDBInvType*) skill level:(int32_t) level account:(NCAccount*) account;

@end
