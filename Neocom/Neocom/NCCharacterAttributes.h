//
//  NCCharacterAttributes.h
//  Neocom
//
//  Created by Artem Shimanski on 21.10.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import <Foundation/Foundation.h>

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

@class EVECharacterSheet;
@class NCDBInvType;
@interface NCCharacterAttributes : NSObject

@property (nonatomic, assign) int32_t intelligence;
@property (nonatomic, assign) int32_t memory;
@property (nonatomic, assign) int32_t charisma;
@property (nonatomic, assign) int32_t perception;
@property (nonatomic, assign) int32_t willpower;

+ (instancetype) defaultCharacterAttributes;
+ (instancetype) characterAttributesWithCharacterSheet:(EVECharacterSheet*) characterSheet;
- (float) skillpointsPerSecondForSkill:(NCDBInvType*) skill;
- (float) skillpointsPerSecondWithPrimaryAttribute:(int32_t) primaryAttributeID secondaryAttribute:(int32_t) secondaryAttributeID;


@end
