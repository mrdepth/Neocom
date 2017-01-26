//
//  NCFittingShip.h
//  Neocom
//
//  Created by Artem Shimanski on 04.01.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

#import "NCFittingItem.h"


@class NCFittingModule, NCFittingDrone;
@interface NCFittingShip : NCFittingItem
@property (readonly, nonnull) NSArray<NCFittingModule*>* modules;
@property (readonly, nonnull) NSArray<NCFittingDrone*>* drones;
@property (nonatomic, assign) NCFittingDamage damagePattern;

- (nonnull instancetype) initWithTypeID:(NSInteger) typeID;

- (nullable NCFittingModule*) addModuleWithTypeID:(NSInteger) typeID NS_SWIFT_NAME(addModule(typeID:));
- (nullable NCFittingModule*) addModuleWithTypeID:(NSInteger) typeID forced:(BOOL) forced socket:(NSInteger) socket NS_SWIFT_NAME(addModule(typeID:forced:socket:));
- (nullable NCFittingModule*) replaceModule:(nonnull NCFittingModule*) module withTypeID:(NSInteger) typeID NS_SWIFT_NAME(replaceModule(module:typeID:));
- (void) removeModule:(nonnull NCFittingModule*) module;
- (nonnull NSArray<NCFittingModule*>*) modulesWithSlot:(NCFittingModuleSlot) slot NS_SWIFT_NAME(modules(slot:));

- (nullable NCFittingDrone*) addDroneWithTypeID:(NSInteger) typeID NS_SWIFT_NAME(addDrone(typeID:));
- (void) removeDrone:(nonnull NCFittingDrone*) drone;


//MARK: Calculations
- (NSInteger) totalSlots:(NCFittingModuleSlot) slot;
- (NSInteger) freeSlots:(NCFittingModuleSlot) slot;
- (NSInteger) usedSlots:(NCFittingModuleSlot) slot;
- (NSInteger) totalHardpoints:(NCFittingModuleHardpoint) hardpoint;
- (NSInteger) freeHardpoints:(NCFittingModuleHardpoint) hardpoint;
- (NSInteger) usedHardpoints:(NCFittingModuleHardpoint) hardpoint;

@property (readonly) double capacity;
@property (readonly) double oreHoldCapacity;

@property (readonly) double calibrationUsed;
@property (readonly) double totalCalibration;
@property (readonly) double powerGridUsed;
@property (readonly) double totalPowerGrid;
@property (readonly) double cpuUsed;
@property (readonly) double totalCPU;
@property (readonly) double droneBandwidthUsed;
@property (readonly) double totalDroneBandwidth;
@property (readonly) double droneBayUsed;
@property (readonly) double totalDroneBay;
@property (readonly) double fighterHangarUsed;
@property (readonly) double totalFighterHangar;

//MARK: Capacitor
@property (readonly) double capCapacity;
@property (readonly) BOOL isCapStable;
@property (readonly) NSTimeInterval capLastsTime;
@property (readonly) double capStableLevel;
@property (readonly) double capUsed;
@property (readonly) double capRecharge;

//MARK: Tank
@property (readonly) NCFittingResistances resistances;
@property (readonly) NCFittingTank tank;
@property (readonly) NCFittingTank effectiveTank;
@property (readonly) NCFittingTank sustainableTank;
@property (readonly) NCFittingTank effectiveSustainableTank;
@property (readonly) NCFittingHitPoints hitPoints;
@property (readonly) NCFittingHitPoints effectiveHitPoints;
@property (readonly) double shieldRecharge;

//MARK: DPS
@property (readonly) NCFittingDamage weaponDPS;
@property (readonly) NCFittingDamage weaponVolley;
- (NCFittingDamage) weaponDPSWithTarget:(NCFittingHostileTarget) target NS_SWIFT_NAME(weaponDPS(target:));
@property (readonly) NCFittingDamage droneDPS;
@property (readonly) NCFittingDamage droneVolley;
- (NCFittingDamage) droneDPSWithTarget:(NCFittingHostileTarget) target NS_SWIFT_NAME(droneDPS(target:));

//MARK: Mobility
@property (readonly) double alignTime;
@property (readonly) double warpSpeed;
@property (readonly) double maxWarpDistance;
@property (readonly) double velocity;
@property (readonly) double signatureRadius;
@property (readonly) double mass;
@property (readonly) double volume;
@property (readonly) double agility;

- (double) maxVelocityInOrbit:(double) orbit NS_SWIFT_NAME(maxVelocity(orbit:));
- (double) orbitRadiusWithTransverseVelocity:(double) velocity NS_SWIFT_NAME(orbitRadius(transverseVelocity:));
- (double) orbitRadiusWithAngularVelocity:(double) velocity NS_SWIFT_NAME(orbitRadius(angularVelocity:));

//MARK: Targeting
@property (readonly) NSInteger maxTargets;
@property (readonly) double maxTargetRange;
@property (readonly) double scanStrength;
@property (readonly) NCFittingScanType scanType;
@property (readonly) double probeSize;
@property (readonly) double scanResolution;

//MARK: Drones
- (NSInteger) droneSquadronLimit:(NCFittingFighterSquadron) squadron;
- (NSInteger) droneSquadronUsed:(NCFittingFighterSquadron) squadron;
@property (readonly) NSInteger totalFighterLaunchTubes;
@property (readonly) NSInteger fighterLaunchTubesUsed;

@end
