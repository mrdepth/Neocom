//
//  NCCharacterAttributes.h
//  Neocom
//
//  Created by Артем Шиманский on 14.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

#define NCCharismaBonusAttributeID 175
#define NCIntelligenceBonusAttributeID 176
#define NCMemoryBonusAttributeID 177
#define NCPerceptionBonusAttributeID 178
#define NCWillpowerBonusAttributeID 179
#define NCPrimaryAttributeAttribteID 180
#define NCSecondaryAttributeAttribteID 181

#define NCCharismaAttributeID 164
#define NCIntelligenceAttributeID 165
#define NCMemoryAttributeID 166
#define NCPerceptionAttributeID 167
#define NCWillpowerAttributeID 168

@class NCDBInvType;
@class EVECharacterSheet;
@class NCTrainingQueue;
@interface NCCharacterAttributes : NSObject<NSCoding>
@property (nonatomic, assign) int32_t intelligence;
@property (nonatomic, assign) int32_t memory;
@property (nonatomic, assign) int32_t charisma;
@property (nonatomic, assign) int32_t perception;
@property (nonatomic, assign) int32_t willpower;

+ (instancetype) defaultCharacterAttributes;
+ (instancetype) optimalAttributesWithTrainingQueue:(NCTrainingQueue*) trainingQueue;
- (id) initWithCharacterSheet:(EVECharacterSheet*) characterSheet;
- (float) skillpointsPerSecondForSkill:(NCDBInvType*) skill;
- (float) skillpointsPerSecondWithPrimaryAttribute:(int32_t) primaryAttributeID secondaryAttribute:(int32_t) secondaryAttributeID;

@end