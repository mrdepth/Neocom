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
@property (nonatomic, strong) NSString *allianceName;
@property (nonatomic, assign) NSInteger characterID;
@property (nonatomic, strong) NSString *characterName;
@property (nonatomic, assign) NSInteger corporationID;
@property (nonatomic, strong) NSString *corporationName;
@property (nonatomic, strong) EVEDBInvType* shipType;
@end

@interface KillMailVictim : KillMailPilot
@property (nonatomic, assign) NSInteger damageTaken;
@end

@interface KillMailAttacker : KillMailPilot
@property (nonatomic, assign) float securityStatus;
@property (nonatomic, assign) NSInteger damageDone;
@property (nonatomic, assign) BOOL finalBlow;
@property (nonatomic, strong) EVEDBInvType* weaponType;
@end

@interface KillMailItem : NSObject
@property (nonatomic, assign) BOOL destroyed;
@property (nonatomic, assign) NSInteger qty;
@property (nonatomic, strong) EVEDBInvType* type;
@end

@interface KillMail : NSObject
@property (nonatomic, strong) NSArray* hiSlots;
@property (nonatomic, strong) NSArray* medSlots;
@property (nonatomic, strong) NSArray* lowSlots;
@property (nonatomic, strong) NSArray* rigSlots;
@property (nonatomic, strong) NSArray* subsystemSlots;
@property (nonatomic, strong) NSArray* droneBay;
@property (nonatomic, strong) NSArray* cargo;
@property (nonatomic, strong) NSMutableArray* attackers;
@property (nonatomic, strong) KillMailVictim* victim;
@property (nonatomic, strong) EVEDBMapSolarSystem* solarSystem;
@property (nonatomic, strong) NSDate* killTime;

- (id) initWithKillLogKill:(EVEKillLogKill*) kill;
- (id) initWithKillNetLogEntry:(EVEKillNetLogEntry*) kill;

@end
