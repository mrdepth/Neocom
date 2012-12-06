//
//  SkillPlan.h
//  EVEUniverse
//
//  Created by Mr. Depth on 1/31/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EVEDBAPI.h"
#import "EVEOnlineAPI.h"

#define NotificationSkillPlanDidChangeSkill @"NotificationSkillPlanDidChangeSkill"
#define NotificationSkillPlanDidAddSkill @"NotificationSkillPlanDidAddSkill"
#define NotificationSkillPlanDidRemoveSkill @"NotificationSkillPlanDidRemoveSkill"

@class EVEAccount;
@class CharacterAttributes;
@interface SkillPlan : NSObject<NSXMLParserDelegate> {
	NSMutableArray* skills;
	NSTimeInterval trainingTime;
	CharacterAttributes* characterAttributes;
	NSDictionary* characterSkills;
	NSInteger characterID;
	NSString* name;
}
@property (nonatomic, retain) NSMutableArray* skills;
@property (nonatomic, readonly) NSTimeInterval trainingTime;
@property (nonatomic, retain) CharacterAttributes* characterAttributes;
@property (nonatomic, retain) NSDictionary* characterSkills;
@property (nonatomic, assign) NSInteger characterID;
@property (nonatomic, retain) NSString* name;

+ (id) skillPlanWithAccount:(EVEAccount*) aAccount;
+ (id) skillPlanWithAccount:(EVEAccount*) aAccount eveMonSkillPlanPath:(NSString*) skillPlanPath;
+ (id) skillPlanWithAccount:(EVEAccount*) aAccount eveMonSkillPlan:(NSString*) skillPlan;
- (id) initWithAccount:(EVEAccount*) aAccount;
- (id) initWithAccount:(EVEAccount*) aAccount eveMonSkillPlanPath:(NSString*) skillPlanPath;
- (id) initWithAccount:(EVEAccount*) aAccount eveMonSkillPlan:(NSString*) skillPlan;

- (void) addSkill:(EVEDBInvTypeRequiredSkill*) skill;
- (void) addType:(EVEDBInvType*) type;
- (void) addCertificate:(EVEDBCrtCertificate*) certificate;
- (void) removeSkill:(EVEDBInvTypeRequiredSkill*) skill;
- (void) resetTrainingTime;
- (void) load;
- (void) save;
- (void) clear;

@end
