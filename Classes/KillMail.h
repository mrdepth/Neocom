//
//  KillMail.h
//  EVEUniverse
//
//  Created by Artem Shimanski on 09.11.12.
//
//

#import <Foundation/Foundation.h>
#import "EVEOnlineAPI.h"
#import "EVEDBAPI.h"
#import "EVEKillNetLog.h"

@interface KillMailPilot : NSObject
@property (nonatomic, assign) NSInteger allianceID;
@property (nonatomic, retain) NSString *allianceName;
@property (nonatomic, assign) NSInteger characterID;
@property (nonatomic, retain) NSString *characterName;
@property (nonatomic, assign) NSInteger corporationID;
@property (nonatomic, retain) NSString *corporationName;
@property (nonatomic, retain) EVEDBInvType* shipType;
@end

@interface KillMailVictim : KillMailPilot
@property (nonatomic, assign) NSInteger damageTaken;
@end

@interface KillMailAttacker : KillMailPilot
@property (nonatomic, assign) float securityStatus;
@property (nonatomic, assign) NSInteger damageDone;
@property (nonatomic, assign) BOOL finalBlow;
@property (nonatomic, retain) EVEDBInvType* weaponType;
@end

@interface KillMailItem : NSObject
@property (nonatomic, assign) BOOL destroyed;
@property (nonatomic, assign) NSInteger qty;
@property (nonatomic, retain) EVEDBInvType* type;
@end

@interface KillMail : NSObject
@property (nonatomic, retain) NSArray* hiSlots;
@property (nonatomic, retain) NSArray* medSlots;
@property (nonatomic, retain) NSArray* lowSlots;
@property (nonatomic, retain) NSArray* rigSlots;
@property (nonatomic, retain) NSArray* subsystemSlots;
@property (nonatomic, retain) NSArray* droneBay;
@property (nonatomic, retain) NSArray* cargo;
@property (nonatomic, retain) NSMutableArray* attackers;
@property (nonatomic, retain) KillMailVictim* victim;
@property (nonatomic, retain) EVEDBMapSolarSystem* solarSystem;
@property (nonatomic, retain) NSDate* killTime;

- (id) initWithKillLogKill:(EVEKillLogKill*) kill;
- (id) initWithKillNetLogEntry:(EVEKillNetLogEntry*) kill;

@end
