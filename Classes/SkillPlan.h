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
#define NotificationSkillPlanDidImportFromCloud @"NotificationSkillPlanDidImportFromCloud"

@class EVEAccount;
@class CharacterAttributes;

@interface SkillPlan : NSManagedObject<NSXMLParserDelegate>

@property (nonatomic, strong) NSMutableArray* skills;
@property (nonatomic, readonly) NSTimeInterval trainingTime;
@property (nonatomic, strong) CharacterAttributes* characterAttributes;
@property (nonatomic, strong) NSDictionary* characterSkills;
@property (nonatomic, strong) NSString* name;

//CoreData
@property (nonatomic, strong) NSString * attributes;
@property (nonatomic) int32_t characterID;
@property (nonatomic, strong) NSString * skillPlanName;
@property (nonatomic, strong) NSString * skillPlanSkills;

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
