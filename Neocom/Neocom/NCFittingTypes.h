//
//  NCFittingTypes.h
//  Neocom
//
//  Created by Artem Shimanski on 05.01.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, NCFittingScanType) {
	NCFittingScanTypeRadar,
	NCFittingScanTypeLadar,
	NCFittingScanTypeMagnetometric,
	NCFittingScanTypeGravimetric,
	NCFittingScanTypeMultispectral
};

typedef NS_ENUM(NSInteger, NCFittingModuleSlot) {
	NCFittingModuleSlotUnknown = -1,
	NCFittingModuleSlotNone = 0,
	NCFittingModuleSlotHi,
	NCFittingModuleSlotMed,
	NCFittingModuleSlotLow,
	NCFittingModuleSlotRig,
	NCFittingModuleSlotSubsystem,
	NCFittingModuleSlotMode,
	NCFittingModuleSlotService
};

typedef NS_ENUM(NSInteger, NCFittingModuleHardpoint) {
	NCFittingModuleHardpointNone = 0,
	NCFittingModuleHardpointLauncher,
	NCFittingModuleHardpointTurret,
};

typedef NS_ENUM(NSInteger, NCFittingModuleState) {
	NCFittingModuleStateUnknown = -1,
	NCFittingModuleStateOffline,
	NCFittingModuleStateOnline,
	NCFittingModuleStateActive,
	NCFittingModuleStateOverloaded
};

typedef NS_ENUM(NSInteger, NCFittingFighterSquadron) {
	NCFittingFighterSquadronNone = 0,
	NCFittingFighterSquadronHeavy,
	NCFittingFighterSquadronLight,
	NCFittingFighterSquadronSupport
};

typedef struct {
	double em;
	double thermal;
	double kinetic;
	double explosive;
} NCFittingDamage;

typedef struct {
	double passiveShield;
	double shieldRepair;
	double armorRepair;
	double hullRepair;
} NCFittingTank;

typedef struct {
	double shield;
	double armor;
	double hull;
} NCFittingHitPoints;

typedef struct {
	NCFittingDamage shield, armor, hull;
} NCFittingResistances;

typedef struct {
	double angularVelocity;
	double velocity;
	double signature;
	double range;
} NCFittingHostileTarget;
