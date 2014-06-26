//
//  NCCharacterAttributes.h
//  Neocom
//
//  Created by Артем Шиманский on 14.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import <Foundation/Foundation.h>

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

@end