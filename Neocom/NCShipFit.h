//
//  NCShipFit.h
//  Neocom
//
//  Created by Artem Shimanski on 17.12.13.
//  Copyright (c) 2013 Artem Shimanski. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "NCFit.h"
#import "eufe.h"

@interface NCShipFitLoadout : NSObject<NSCoding>
@property (nonatomic, strong) NSArray* hiSlots;
@property (nonatomic, strong) NSArray* medSlots;
@property (nonatomic, strong) NSArray* lowSlots;
@property (nonatomic, strong) NSArray* rigSlots;
@property (nonatomic, strong) NSArray* subsystems;
@property (nonatomic, strong) NSArray* drones;
@property (nonatomic, strong) NSArray* cargo;
@property (nonatomic, strong) NSArray* implants;
@property (nonatomic, strong) NSArray* boosters;
@end

@interface NCShipFitLoadoutModule : NSObject<NSCoding>
@property (nonatomic, assign) eufe::TypeID typeID;
@property (nonatomic, assign) eufe::TypeID chargeID;
@property (nonatomic, assign) eufe::Module::State state;
@end

@interface NCShipFitLoadoutDrone : NSObject<NSCoding>
@property (nonatomic, assign) eufe::TypeID typeID;
@property (nonatomic, assign) int32_t count;
@property (nonatomic, assign) bool active;
@end

@interface NCShipFitLoadoutImplant : NSObject<NSCoding>
@property (nonatomic, assign) eufe::TypeID typeID;
@end

@interface NCShipFitLoadoutBooster : NSObject<NSCoding>
@property (nonatomic, assign) eufe::TypeID typeID;
@end

@interface NCShipFitLoadoutCargoItem : NSObject<NSCoding>
@property (nonatomic, assign) eufe::TypeID typeID;
@property (nonatomic, assign) int32_t count;
@end

@interface NCShipFit : NCFit

@property (nonatomic, retain) NCFitLoadout* loadout;

+ (instancetype) emptyFit;
+ (NSArray*) allFits;

- (void) saveFromCharacter:(eufe::Character*) character;
- (void) loadToCharacter:(eufe::Character*) character;


@end
