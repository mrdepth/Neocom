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
@property (nonatomic, assign) NSInteger skillPoints;
@property (nonatomic, assign) NSInteger currentLevel;
@property (nonatomic, assign) NSInteger targetLevel;
@property (nonatomic, assign) NSInteger trainedLevel;
@property (nonatomic, assign, readonly) NSInteger targetSkillPoints;
@property (nonatomic, assign, getter = isActive) BOOL active;
@property (nonatomic, strong, readonly) NSString* skillName;
@property (nonatomic, strong) NCCharacterAttributes* characterAttributes;
@property (nonatomic, assign) NSTimeInterval trainingTimeToLevelUp;
@property (nonatomic, assign) NSTimeInterval trainingTimeToFinish;

- (NSTimeInterval) trainingTimeToLevelUpWithCharacterAttributes:(NCCharacterAttributes*) attributes;
- (NSTimeInterval) trainingTimeToFinishWithCharacterAttributes:(NCCharacterAttributes*) attributes;

@end
