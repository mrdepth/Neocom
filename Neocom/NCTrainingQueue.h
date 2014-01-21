//
//  NCTrainingQueue.h
//  Neocom
//
//  Created by Артем Шиманский on 15.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EVEDBAPI.h"
#import "NCSkillData.h"

@class NCAccount;
@interface NCTrainingQueue : NSObject<NSCopying>
@property (nonatomic, copy) NSArray* skills;
@property (nonatomic, readonly, assign) NSTimeInterval trainingTime;

- (id) initWithAccount:(NCAccount*) account;
- (void) addRequiredSkillsForType:(EVEDBInvType*) type;
- (void) addSkill:(EVEDBInvType*) skill withLevel:(NSInteger) level;
- (void) removeSkill:(NCSkillData*) skill;

@end
