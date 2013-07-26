//
//  TrainingQueue.h
//  EVEUniverse
//
//  Created by Artem Shimanski on 2/24/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EVEDBAPI.h"

@interface EVEDBInvTypeRequiredSkill(TrainingQueue)

@property (nonatomic) NSInteger currentLevel;
@property (nonatomic) float currentSP;

@end


@class EVESkillQueue;
@class EVEAccount;
@interface TrainingQueue : NSObject

@property (nonatomic, strong) NSMutableArray *skills;
@property (nonatomic, readonly, assign) NSTimeInterval trainingTime;

+ (id) trainingQueueWithType: (EVEDBInvType*) type;
+ (id) trainingQueueWithCertificate: (EVEDBCrtCertificate*) certificate;
+ (id) trainingQueueWithRequiredSkills: (NSArray*) requiredSkills;
- (id) initWithType: (EVEDBInvType*) type;
- (id) initWithCertificate: (EVEDBCrtCertificate*) certificate;
- (id) initWithRequiredSkills: (NSArray*) requiredSkills;
//- (void) addSkillID:(NSInteger) typeID level:(NSInteger) level;
- (void) addSkill:(EVEDBInvTypeRequiredSkill*) skill;

@end
