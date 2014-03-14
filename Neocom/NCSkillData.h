//
//  NCSkillData.h
//  Neocom
//
//  Created by Артем Шиманский on 14.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "EVEDBAPI.h"

@class EVEDBInvType;
@class NCCharacterAttributes;
@interface NCSkillData : EVEDBInvType<NSCoding>
@property (nonatomic, assign) int32_t skillPoints;
@property (nonatomic, assign) int32_t currentLevel;
@property (nonatomic, assign) int32_t targetLevel;
@property (nonatomic, assign) int32_t trainedLevel;
@property (nonatomic, assign, readonly) int32_t targetSkillPoints;
@property (nonatomic, assign, getter = isActive) BOOL active;
@property (nonatomic, strong, readonly) NSString* skillName;
@property (nonatomic, strong) NCCharacterAttributes* characterAttributes;
@property (nonatomic, assign) NSTimeInterval trainingTimeToLevelUp;
@property (nonatomic, assign) NSTimeInterval trainingTimeToFinish;
@property (nonatomic, readonly) int32_t skillPointsToFinish;
@property (nonatomic, readonly) int32_t skillPointsToLevelUp;

- (NSTimeInterval) trainingTimeToLevelUpWithCharacterAttributes:(NCCharacterAttributes*) attributes;
- (NSTimeInterval) trainingTimeToFinishWithCharacterAttributes:(NCCharacterAttributes*) attributes;

@end
