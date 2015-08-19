//
//  NCTrainingQueue.h
//  Neocom
//
//  Created by Артем Шиманский on 15.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NCSkillData.h"

@class NCAccount;
@class EVECharacterSheet;
@class EVESkillQueue;
@interface NCTrainingQueue : NSObject<NSCopying>
@property (nonatomic, copy, readonly) NSArray* skills;
@property (nonatomic, readonly, assign) NSTimeInterval trainingTime;
@property (nonatomic, strong) EVECharacterSheet* characterSheet;
@property (nonatomic, strong) NCCharacterAttributes* characterAttributes;

- (id) initWithCharacterSheet:(EVECharacterSheet*) characterSheet;
- (id) initWithCharacterSheet:(EVECharacterSheet*) characterSheet xmlData:(NSData*) data skillPlanName:(NSString**) skillPlanName;

- (void) addRequiredSkillsForType:(NCDBInvType*) type;
- (void) addSkill:(NCDBInvType*) skill withLevel:(int32_t) level;
- (void) addMastery:(NCDBCertMastery*) mastery;
- (void) removeSkill:(NCSkillData*) skill;
- (NSString*) xmlRepresentationWithSkillPlanName:(NSString*) skillPlanName;
- (NSTimeInterval) trainingTimeWithCharacterAttributes:(NCCharacterAttributes*) characterAttributes;

@end
