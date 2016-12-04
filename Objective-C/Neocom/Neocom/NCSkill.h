//
//  NCSkill.h
//  Neocom
//
//  Created by Artem Shimanski on 12.11.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import <Foundation/Foundation.h>

#define NCSkillTimeConstantAttributeID 275

@class NCDBInvType, NCCharacterAttributes, EVESkillQueueItem, EVESkillQueue;
@interface NCSkill : NSObject
@property (nonatomic, assign, readonly) int32_t typeID;
@property (nonatomic, copy, readonly) NSString* typeName;
@property (nonatomic, assign, readonly) int32_t primaryAttributeID;
@property (nonatomic, assign, readonly) int32_t secondaryAttributeID;
@property (nonatomic, assign, readonly) int32_t rank;
@property (nonatomic, assign) int32_t startSkillPoints;
@property (nonatomic, readonly) int32_t skillPoints;
@property (nonatomic, readonly) float trainingProgress;
@property (nonatomic, assign) int32_t level;
@property (nonatomic, strong) NSDate* trainingStartDate;
@property (nonatomic, strong) NSDate* trainingEndDate;

- (id) initWithInvType:(NCDBInvType*) type;
- (id) initWithInvType:(NCDBInvType*) type skill:(EVESkillQueueItem*) skill inQueue:(EVESkillQueue*) skillQueue;
- (id) initWithSkill:(EVESkillQueueItem*) skill inQueue:(EVESkillQueue*) skillQueue;
- (NSTimeInterval) trainingTimeToLevelUpWithCharacterAttributes:(NCCharacterAttributes*) attributes;
- (int32_t) skillPointsAtLevel:(int32_t) level;

@end
