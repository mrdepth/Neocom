//
//  NCKillMail.h
//  Neocom
//
//  Created by Артем Шиманский on 21.02.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <EVEAPI/EVEAPI.h>

@class EVEKillNetLogEntry;
@class NCDBInvType;
@class NCDBMapSolarSystem;

@interface NCKillMailPilot : NSObject<NSCoding>
@property (nonatomic, assign) int32_t allianceID;
@property (nonatomic, strong) NSString *allianceName;
@property (nonatomic, assign) int32_t characterID;
@property (nonatomic, strong) NSString *characterName;
@property (nonatomic, assign) int32_t corporationID;
@property (nonatomic, strong) NSString *corporationName;
@property (nonatomic, assign) int32_t shipTypeID;
@end

@interface NCKillMailVictim : NCKillMailPilot
@property (nonatomic, assign) int32_t damageTaken;
@end

@interface NCKillMailAttacker : NCKillMailPilot
@property (nonatomic, assign) float securityStatus;
@property (nonatomic, assign) int32_t damageDone;
@property (nonatomic, assign) BOOL finalBlow;
@property (nonatomic, assign) int32_t weaponTypeID;
@end

@interface NCKillMailItem : NSObject<NSCoding>
@property (nonatomic, assign) BOOL destroyed;
@property (nonatomic, assign) int32_t qty;
@property (nonatomic, assign) int32_t typeID;
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
@property (nonatomic, assign) int32_t solarSystemID;
@property (nonatomic, strong) NSDate* killTime;

//- (id) initWithKillLogKill:(EVEKillLogKill*) kill;
- (id) initWithKillMailsKill:(EVEKillMailsKill*) kill databaseManagedObjectContext:(NSManagedObjectContext*) databaseManagedObjectContext;
//- (id) initWithKillNetLogEntry:(EVEKillNetLogEntry*) kill;

@end