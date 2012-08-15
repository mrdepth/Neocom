//
//  TrainingQueue.h
//  EVEUniverse
//
//  Created by Artem Shimanski on 2/24/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EVEDBAPI.h"

@interface EVEDBInvTypeRequiredSkill(TrainingQueueSkill)

@property (nonatomic) NSInteger currentLevel;
@property (nonatomic) float currentSP;

//- (id) initWithTypeID:(NSInteger) typeID characterSkills:(NSDictionary*) characterSkills requiredLevel:(NSInteger) requiredLevel error:(NSError**) error;
//- (id) initWithInvType:(EVEDBInvType *) skill characterSkills:(NSDictionary*) characterSkills requiredLevel:(NSInteger) aRequiredLevel;

@end


@class EVESkillQueue;
@class EVEAccount;
@interface TrainingQueue : NSObject {
	NSMutableArray *skills;
	NSTimeInterval trainingTime;
@private
	EVEAccount *account;
	NSDictionary *characterSkills;
}

@property (nonatomic, retain) NSMutableArray *skills;
@property (nonatomic, readonly) NSTimeInterval trainingTime;

+ (id) trainingQueueWithType: (EVEDBInvType*) type;
+ (id) trainingQueueWithCertificate: (EVEDBCrtCertificate*) certificate;
+ (id) trainingQueueWithRequiredSkills: (NSArray*) requiredSkills;
- (id) initWithType: (EVEDBInvType*) type;
- (id) initWithCertificate: (EVEDBCrtCertificate*) certificate;
- (id) initWithRequiredSkills: (NSArray*) requiredSkills;
//- (void) addSkillID:(NSInteger) typeID level:(NSInteger) level;
- (void) addSkill:(EVEDBInvTypeRequiredSkill*) skill;

@end
