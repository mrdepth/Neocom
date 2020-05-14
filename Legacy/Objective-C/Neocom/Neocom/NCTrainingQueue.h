//
//  NCTrainingQueue.h
//  Neocom
//
//  Created by Artem Shimanski on 13.11.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NCSkill.h"

@interface NCTrainingQueueSkill : NCSkill
@property (nonatomic, assign) int32_t targetLevel;
- (NSTimeInterval) trainingTimeWithCharacterAttributes:(NCCharacterAttributes*) attributes;
@end

@class NCCharacter, NCCharacterAttributes, EVESkillQueue;
@interface NCTrainingQueue : NSObject
@property (nonatomic, strong, readonly) NSArray<NCTrainingQueueSkill*>* skills;

- (instancetype) initWithCharacter:(NCCharacter*) character;
- (instancetype) initWithSkillQueue:(EVESkillQueue*) skillQueue;

@end
