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
@interface NCKillMailPilot : NSObject<NSCoding>
@property (nonatomic, assign) NSInteger allianceID;
@property (nonatomic, strong) NSString *allianceName;
@property (nonatomic, assign) NSInteger characterID;
@property (nonatomic, strong) NSString *characterName;
@property (nonatomic, assign) NSInteger corporationID;
@property (nonatomic, strong) NSString *corporationName;
@property (nonatomic, strong) EVEDBInvType* shipType;
@end

@interface NCKillMailVictim : NCKillMailPilot
@property (nonatomic, assign) NSInteger damageTaken;
@end

@interface NCKillMailAttacker : NCKillMailPilot
@property (nonatomic, assign) float securityStatus;
@property (nonatomic, assign) NSInteger damageDone;
@property (nonatomic, assign) BOOL finalBlow;
@property (nonatomic, strong) EVEDBInvType* weaponType;
@end

@interface NCKillMailItem : NSObject<NSCoding>
@property (nonatomic, assign) BOOL destroyed;
@property (nonatomic, assign) NSInteger qty;
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