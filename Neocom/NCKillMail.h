//
//  NCKillMail.h
//  Neocom
//
//  Created by Артем Шиманский on 21.02.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EVEDBAPI.h"
#import "EVEOnlineAPI.h"

@class EVEKillNetLogEntry;
@class NCDBInvType;
@interface NCKillMailPilot : NSObject<NSCoding>
@property (nonatomic, assign) int32_t allianceID;
@property (nonatomic, strong) NSString *allianceName;
@property (nonatomic, assign) int32_t characterID;
@property (nonatomic, strong) NSString *characterName;
@property (nonatomic, assign) int32_t corporationID;
@property (nonatomic, strong) NSString *corporationName;
@property (nonatomic, strong) NCDBInvType* shipType;
@end

@interface NCKillMailVictim : NCKillMailPilot
@property (nonatomic, assign) int32_t damageTaken;
@end

@interface NCKillMailAttacker : NCKillMailPilot
@property (nonatomic, assign) float securityStatus;
@property (nonatomic, assign) int32_t damageDone;
@property (nonatomic, assign) BOOL finalBlow;
@property (nonatomic, strong) EVEDBInvType* weaponType;
@end

@interface NCKillMailItem : NSObject<NSCoding>
@property (nonatomic, assign) BOOL destroyed;
@property (nonatomic, assign) int32_t qty;
@property (nonatomic, strong) EVEDBInvType* type;
@property (nonatomic, assign) EVEInventoryFlag flag;
@end

@interface NCKillMail : NSObject<NSCoding>
@property (nonatomic, strong) NSArray* hiSlots;
@property (nonatomic, strong) NSArray* medSlots;
@property (nonatomic, strong) NSArray* lowSlots;
@property (nonatomic, strong) NSArray* rigSlots;
@property (nonatomic, strong) NSArray* subsystemSlots;
@property (nonatomic, strong) NSArray* droneBay;
@property (nonatomic, strong) NSArray* cargo;
@property (nonatomic, strong) NSMutableArray* attackers;
@property (nonatomic, strong) NCKillMailVictim* victim;
@property (nonatomic, strong) EVEDBMapSolarSystem* solarSystem;
@property (nonatomic, strong) NSDate* killTime;

- (id) initWithKillLogKill:(EVEKillLogKill*) kill;
- (id) initWithKillNetLogEntry:(EVEKillNetLogEntry*) kill;

@end