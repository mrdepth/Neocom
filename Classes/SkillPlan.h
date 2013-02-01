//
//  SkillPlan.h
//  EVEUniverse
//
//  Created by Artem Shimanski on 25.01.13.
//
//

#import <Foundation/Foundation.h>
#import "EVEDBAPI.h"
#import "EVEOnlineAPI.h"

#define NotificationSkillPlanDidChangeSkill @"NotificationSkillPlanDidChangeSkill"
#define NotificationSkillPlanDidAddSkill @"NotificationSkillPlanDidAddSkill"
#define NotificationSkillPlanDidRemoveSkill @"NotificationSkillPlanDidRemoveSkill"

@class EVEAccount;
@class CharacterAttributes;

@interface SkillPlan : NSManagedObject<NSXMLParserDelegate>

@property (nonatomic, retain) NSMutableArray* skills;
@property (nonatomic, readonly) NSTimeInterval trainingTime;
@property (nonatomic, retain) CharacterAttributes* characterAttributes;
@property (nonatomic, retain) NSDictionary* characterSkills;
@property (nonatomic, retain) NSString* name;

//CoreData
@property (nonatomic, retain) NSString * attributes;
@property (nonatomic) int32_t characterID;
@property (nonatomic, retain) NSString * skillPlanName;
@property (nonatomic, retain) NSString * skillPlanSkills;

+ (id) skillPlanWithAccount:(EVEAccount*) aAccount name:(NSString*) name;
+ (id) skillPlanWithAccount:(EVEAccount*) aAccount eveMonSkillPlanPath:(NSString*) skillPlanPath;
+ (id) skillPlanWithAccount:(EVEAccount*) aAccount eveMonSkillPlan:(NSString*) skillPlan;
- (id) initWithAccount:(EVEAccount*) aAccount;

- (void) addSkill:(EVEDBInvTypeRequiredSkill*) skill;
- (void) addType:(EVEDBInvType*) type;
- (void) addCertificate:(EVEDBCrtCertificate*) certificate;
- (void) removeSkill:(EVEDBInvTypeRequiredSkill*) skill;
- (void) resetTrainingTime;
- (void) load;
- (void) save;
- (void) clear;

@end
