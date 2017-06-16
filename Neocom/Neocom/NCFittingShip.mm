//
//  NCFittingShip.m
//  Neocom
//
//  Created by Artem Shimanski on 04.01.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

#import "NCFittingShip.h"
#import "NCFittingProtected.h"

@implementation NCFittingShip {
	NSInteger _typeID;
}

- (nonnull NSString*) name {
	NCVerifyFittingContext(self.engine);
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	return ship ? [NSString stringWithCString:ship->getName() ?: "" encoding:NSUTF8StringEncoding] : @"";
}

- (void) setName:(NSString *)name {
	NCVerifyFittingContext(self.engine);
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	if (ship) {
		ship->setName(name.UTF8String);
		[self.engine updateWithItem: self];
	}
}

- (nonnull instancetype) initWithTypeID:(NSInteger) typeID {
	if (self = [super init]) {
		_typeID = typeID;
	}
	return self;
}

- (NSInteger) typeID {
	return self.item ? [super typeID] : _typeID;
}

- (nonnull NSArray<NCFittingModule*>*) modules {
	NCVerifyFittingContext(self.engine);
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	if (ship) {
		dgmpp::ModulesList modules = ship->getModules(true);
		NSMutableArray* array = [NSMutableArray new];
		for (auto i: modules) {
			[array addObject:(NCFittingModule*) [NCFittingItem item:i withEngine:self.engine]];
		}
		return array;
	}
	else {
		return @[];
	}
}

- (nonnull NSArray<NCFittingDrone*>*) drones {
	NCVerifyFittingContext(self.engine);
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	if (ship) {
		NSMutableArray* array = [NSMutableArray new];
		for (auto i: ship->getDrones()) {
			[array addObject:(NCFittingDrone*) [NCFittingItem item:i withEngine:self.engine]];
		}
		return array;
	}
	else {
		return @[];
	}
}

- (NCFittingDamage) damagePattern {
	NCVerifyFittingContext(self.engine);
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	NCFittingDamage result;
	
	if (ship) {
		auto damage = ship->getDamagePattern();
		
		result.em = damage.emAmount;
		result.thermal = damage.thermalAmount;
		result.kinetic = damage.kineticAmount;
		result.explosive = damage.explosiveAmount;
	}
	
	return result;
}

- (void) setDamagePattern:(NCFittingDamage)damagePattern {
	NCVerifyFittingContext(self.engine);
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);

	if (ship) {
		dgmpp::DamagePattern result;
		result.emAmount = damagePattern.em;
		result.thermalAmount = damagePattern.thermal;
		result.kineticAmount = damagePattern.kinetic;
		result.explosiveAmount = damagePattern.explosive;
		ship->setDamagePattern(result);
		[self.engine updateWithItem: self];
	}
}

- (nullable NCFittingModule*) addModuleWithTypeID:(NSInteger) typeID {
	return [self addModuleWithTypeID:typeID forced:false socket:-1];
}

- (nullable NCFittingModule*) addModuleWithTypeID:(NSInteger) typeID socket:(NSInteger) socket {
	return [self addModuleWithTypeID:typeID forced:false socket:socket];
}

- (nullable NCFittingModule*) addModuleWithTypeID:(NSInteger) typeID forced:(BOOL) forced socket:(NSInteger) socket {
	NCVerifyFittingContext(self.engine);
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	if (ship) {
		auto module = ship->addModule(static_cast<dgmpp::TypeID>(typeID), forced, static_cast<int>(socket));
		[self.engine updateWithItem: self];
		NCFittingModule* m = module ? (NCFittingModule*) [NCFittingItem item:module withEngine:self.engine] : nil;
		m.factorReload = self.engine.factorReload;
		return m;
	}
	else {
		return nil;
	}
}

- (nullable NCFittingModule*) replaceModule:(nonnull NCFittingModule*) module withTypeID:(NSInteger) typeID {
	NCVerifyFittingContext(self.engine);
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	if (ship) {
		auto result = ship->replaceModule(std::dynamic_pointer_cast<dgmpp::Module>(module.item), static_cast<dgmpp::TypeID>(typeID));
		NSString* identifier = [self.engine identifierForItem:module];
		module = result ? (NCFittingModule*) [NCFittingItem item:result withEngine:self.engine] : nil;
		if (module) {
			module.factorReload = self.engine.factorReload;
			[self.engine assignIdentifier:identifier forItem:module];
		}
		[self.engine updateWithItem: self];
		return module;
	}
	else {
		return nil;
	}
}

- (void) removeModule:(nonnull NCFittingModule*) module {
	NCVerifyFittingContext(self.engine);
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	if (ship) {
		[self.engine assignIdentifier:nil forItem:module];
		ship->removeModule(std::dynamic_pointer_cast<dgmpp::Module>(module.item));
		
		[self.engine updateWithItem: self];
	}
}

- (nonnull NSArray<NCFittingModule*>*) modulesWithSlot:(NCFittingModuleSlot) slot {
	NCVerifyFittingContext(self.engine);
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	if (ship) {
		dgmpp::ModulesList modules = ship->getModules(static_cast<dgmpp::Module::Slot>(slot), true);
		NSMutableArray* array = [NSMutableArray new];
		for (auto i: modules) {
			[array addObject:(NCFittingModule*) [NCFittingItem item:i withEngine:self.engine]];
		}
		return array;
	}
	else {
		return @[];
	}
}

- (nullable NCFittingDrone*) addDroneWithTypeID:(NSInteger) typeID {
	return [self addDroneWithTypeID:typeID squadronTag:-1];
}

- (nullable NCFittingDrone*) addDroneWithTypeID:(NSInteger) typeID squadronTag:(NSInteger) squadronTag {
	NCVerifyFittingContext(self.engine);
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	if (ship) {
		auto drone = ship->addDrone(static_cast<dgmpp::TypeID>(typeID), static_cast<int>(squadronTag));
		[self.engine updateWithItem: self];
		return drone ? (NCFittingDrone*) [NCFittingItem item:drone withEngine:self.engine] : nil;
	}
	else {
		return nil;
	}
}

- (void) removeDrone:(nonnull NCFittingDrone*) drone {
	NCVerifyFittingContext(self.engine);
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	if (ship) {
		[self.engine assignIdentifier:nil forItem:drone];
		ship->removeDrone(std::dynamic_pointer_cast<dgmpp::Drone>(drone.item));
		[self.engine updateWithItem: self];
	}
}

//MARK: Calculations

- (NSInteger) totalSlots:(NCFittingModuleSlot) slot {
	NCVerifyFittingContext(self.engine);
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	return ship ? ship->getNumberOfSlots(static_cast<dgmpp::Module::Slot>(slot)) : 0;
}

- (NSInteger) freeSlots:(NCFittingModuleSlot) slot {
	NCVerifyFittingContext(self.engine);
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	return ship ? ship->getFreeSlots(static_cast<dgmpp::Module::Slot>(slot)) : 0;
}

- (NSInteger) usedSlots:(NCFittingModuleSlot) slot {
	NCVerifyFittingContext(self.engine);
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	return ship ? ship->getUsedSlots(static_cast<dgmpp::Module::Slot>(slot)) : 0;
}

- (NSInteger) totalHardpoints:(NCFittingModuleHardpoint) hardpoint {
	NCVerifyFittingContext(self.engine);
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	return ship ? ship->getNumberOfHardpoints(static_cast<dgmpp::Module::Hardpoint>(hardpoint)) : 0;
}

- (NSInteger) freeHardpoints:(NCFittingModuleHardpoint) hardpoint {
	NCVerifyFittingContext(self.engine);
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	return ship ? ship->getFreeHardpoints(static_cast<dgmpp::Module::Hardpoint>(hardpoint)) : 0;
}

- (NSInteger) usedHardpoints:(NCFittingModuleHardpoint) hardpoint {
	NCVerifyFittingContext(self.engine);
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	return ship ? ship->getUsedHardpoints(static_cast<dgmpp::Module::Hardpoint>(hardpoint)) : 0;
}

- (NSInteger) rigSize {
	NCVerifyFittingContext(self.engine);
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	return ship ? ship->getRigSize() : 0;
}

- (NSInteger) raceID {
	NCVerifyFittingContext(self.engine);
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	return ship ? ship->getRaceID() : 0;
}

- (double) capacity {
	NCVerifyFittingContext(self.engine);
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	return ship ? ship->getCapacity() : 0;
}

- (double) oreHoldCapacity {
	NCVerifyFittingContext(self.engine);
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	return ship ? ship->getOreHoldCapacity() : 0;
}

- (double) calibrationUsed {
	NCVerifyFittingContext(self.engine);
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	return ship ? ship->getCalibrationUsed() : 0;
}

- (double) totalCalibration {
	NCVerifyFittingContext(self.engine);
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	return ship ? ship->getTotalCalibration() : 0;
}

- (double) powerGridUsed {
	NCVerifyFittingContext(self.engine);
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	return ship ? ship->getPowerGridUsed() : 0;
}

- (double) totalPowerGrid {
	NCVerifyFittingContext(self.engine);
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	return ship ? ship->getTotalPowerGrid() : 0;
}

- (double) cpuUsed {
	NCVerifyFittingContext(self.engine);
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	return ship ? ship->getCpuUsed() : 0;
}

- (double) totalCPU {
	NCVerifyFittingContext(self.engine);
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	return ship ? ship->getTotalCpu() : 0;
}

- (double) droneBandwidthUsed {
	NCVerifyFittingContext(self.engine);
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	return ship ? ship->getDroneBandwidthUsed() : 0;
}

- (double) totalDroneBandwidth {
	NCVerifyFittingContext(self.engine);
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	return ship ? ship->getTotalDroneBandwidth() : 0;
}

- (double) droneBayUsed {
	NCVerifyFittingContext(self.engine);
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	return ship ? ship->getDroneBayUsed() : 0;
}

- (double) totalDroneBay {
	NCVerifyFittingContext(self.engine);
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	return ship ? ship->getTotalDroneBay() : 0;
}

- (double) fighterHangarUsed {
	NCVerifyFittingContext(self.engine);
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	return ship ? ship->getFighterHangarUsed() : 0;
}

- (double) totalFighterHangar {
	NCVerifyFittingContext(self.engine);
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	return ship ? ship->getTotalFighterHangar() : 0;
}

//MARK: Capacitor

- (double) capCapacity {
	NCVerifyFittingContext(self.engine);
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	return ship ? ship->getCapCapacity() : 0;
}

- (BOOL) isCapStable {
	NCVerifyFittingContext(self.engine);
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	return ship ? ship->isCapStable() : NO;
}

- (NSTimeInterval) capLastsTime {
	NCVerifyFittingContext(self.engine);
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	return ship ? ship->getCapLastsTime() : 0;
}

- (double) capStableLevel {
	NCVerifyFittingContext(self.engine);
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	return ship ? ship->getCapStableLevel() : 0;
}

- (double) capUsed {
	NCVerifyFittingContext(self.engine);
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	return ship ? ship->getCapUsed() : 0;
}

- (double) capRecharge {
	NCVerifyFittingContext(self.engine);
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	return ship ? ship->getCapRecharge() : 0;
}

- (double) capRechargeTime {
	NCVerifyFittingContext(self.engine);
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	return ship ? ship->getCapRechargeTime() : 0;
}

//MARK: Tank

- (NCFittingResistances) resistances {
	NCVerifyFittingContext(self.engine);
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	NCFittingResistances result;
	
	if (ship) {
		auto resistances = ship->getResistances();
		
		result.shield.em = resistances.shield.em;
		result.shield.thermal = resistances.shield.thermal;
		result.shield.kinetic = resistances.shield.kinetic;
		result.shield.explosive = resistances.shield.explosive;
		
		result.armor.em = resistances.armor.em;
		result.armor.thermal = resistances.armor.thermal;
		result.armor.kinetic = resistances.armor.kinetic;
		result.armor.explosive = resistances.armor.explosive;
		
		result.hull.em = resistances.hull.em;
		result.hull.thermal = resistances.hull.thermal;
		result.hull.kinetic = resistances.hull.kinetic;
		result.hull.explosive = resistances.hull.explosive;
	}

	return result;
}

- (NCFittingTank) tank {
	NCVerifyFittingContext(self.engine);
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	NCFittingTank result;
	
	if (ship) {
		auto tank = ship->getTank();

		result.passiveShield = tank.passiveShield;
		result.shieldRepair = tank.shieldRepair;
		result.armorRepair = tank.armorRepair;
		result.hullRepair = tank.hullRepair;
	}
	
	return result;
}

- (NCFittingTank) effectiveTank {
	NCVerifyFittingContext(self.engine);
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	NCFittingTank result;
	
	if (ship) {
		auto tank = ship->getEffectiveTank();
		
		result.passiveShield = tank.passiveShield;
		result.shieldRepair = tank.shieldRepair;
		result.armorRepair = tank.armorRepair;
		result.hullRepair = tank.hullRepair;
	}
	
	return result;
}

- (NCFittingTank) sustainableTank {
	NCVerifyFittingContext(self.engine);
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	NCFittingTank result;
	
	if (ship) {
		auto tank = ship->getSustainableTank();

		result.passiveShield = tank.passiveShield;
		result.shieldRepair = tank.shieldRepair;
		result.armorRepair = tank.armorRepair;
		result.hullRepair = tank.hullRepair;
	}
	
	return result;
}

- (NCFittingTank) effectiveSustainableTank {
	NCVerifyFittingContext(self.engine);
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	NCFittingTank result;
	
	if (ship) {
		auto tank = ship->getEffectiveSustainableTank();
		
		result.passiveShield = tank.passiveShield;
		result.shieldRepair = tank.shieldRepair;
		result.armorRepair = tank.armorRepair;
		result.hullRepair = tank.hullRepair;
	}
	
	return result;
}

- (NCFittingHitPoints) hitPoints {
	NCVerifyFittingContext(self.engine);
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	NCFittingHitPoints result;
	
	if (ship) {
		auto hitPoints = ship->getHitPoints();

		result.shield = hitPoints.shield;
		result.armor = hitPoints.armor;
		result.hull = hitPoints.hull;
	}
	
	return result;
}

- (NCFittingHitPoints) effectiveHitPoints {
	NCVerifyFittingContext(self.engine);
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	NCFittingHitPoints result;
	
	if (ship) {
		auto hitPoints = ship->getEffectiveHitPoints();

		result.shield = hitPoints.shield;
		result.armor = hitPoints.armor;
		result.hull = hitPoints.hull;
	}
	
	return result;
}

- (double) shieldRecharge {
	NCVerifyFittingContext(self.engine);
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	return ship ? ship->getShieldRecharge() : 0;
}

//MARK: DPS
- (NCFittingDamage) weaponDPS {
	NCVerifyFittingContext(self.engine);
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	NCFittingDamage result;
	
	if (ship) {
		auto damage = ship->getWeaponDps();

		result.em = damage.emAmount;
		result.thermal = damage.thermalAmount;
		result.kinetic = damage.kineticAmount;
		result.explosive = damage.explosiveAmount;
	}
	
	return result;
}

- (NCFittingDamage) weaponVolley {
	NCVerifyFittingContext(self.engine);
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	NCFittingDamage result;
	
	if (ship) {
		auto damage = ship->getWeaponVolley();

		result.em = damage.emAmount;
		result.thermal = damage.thermalAmount;
		result.kinetic = damage.kineticAmount;
		result.explosive = damage.explosiveAmount;
	}
	
	return result;
}

- (NCFittingDamage) weaponDPSWithTarget:(NCFittingHostileTarget) target {
	NCVerifyFittingContext(self.engine);
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	NCFittingDamage result;
	
	if (ship) {
		dgmpp::HostileTarget hostileTarget(target.range, target.angularVelocity, target.signature, target.velocity);
		auto damage = ship->getWeaponDps(hostileTarget);

		result.em = damage.emAmount;
		result.thermal = damage.thermalAmount;
		result.kinetic = damage.kineticAmount;
		result.explosive = damage.explosiveAmount;
	}
	
	return result;
}

- (NCFittingDamage) droneDPS {
	NCVerifyFittingContext(self.engine);
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	NCFittingDamage result;
	
	if (ship) {
		auto damage = ship->getDroneDps();

		result.em = damage.emAmount;
		result.thermal = damage.thermalAmount;
		result.kinetic = damage.kineticAmount;
		result.explosive = damage.explosiveAmount;
	}
	
	return result;
}

- (NCFittingDamage) droneVolley {
	NCVerifyFittingContext(self.engine);
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	NCFittingDamage result;
	
	if (ship) {
		auto damage = ship->getDroneVolley();

		result.em = damage.emAmount;
		result.thermal = damage.thermalAmount;
		result.kinetic = damage.kineticAmount;
		result.explosive = damage.explosiveAmount;
	}
	
	return result;
}

- (NCFittingDamage) droneDPSWithTarget:(NCFittingHostileTarget) target {
	NCVerifyFittingContext(self.engine);
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	NCFittingDamage result;
	
	if (ship) {
		dgmpp::HostileTarget hostileTarget(target.range, target.angularVelocity, target.signature, target.velocity);
		auto damage = ship->getDroneDps(hostileTarget);

		result.em = damage.emAmount;
		result.thermal = damage.thermalAmount;
		result.kinetic = damage.kineticAmount;
		result.explosive = damage.explosiveAmount;
	}
	
	return result;
}

//MARK: Mining

- (double) minerYield {
	NCVerifyFittingContext(self.engine);
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	return ship ? ship->getMinerYield() : 0;
}

- (double) droneYield {
	NCVerifyFittingContext(self.engine);
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	return ship ? ship->getDroneYield() : 0;
}

//MARK: Mobility

- (double) alignTime {
	NCVerifyFittingContext(self.engine);
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	return ship ? ship->getAlignTime() : 0;
}

- (double) warpSpeed {
	NCVerifyFittingContext(self.engine);
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	return ship ? ship->getWarpSpeed() : 0;
}

- (double) maxWarpDistance {
	NCVerifyFittingContext(self.engine);
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	return ship ? ship->getMaxWarpDistance() : 0;
}

- (double) velocity {
	NCVerifyFittingContext(self.engine);
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	return ship ? ship->getVelocity() : 0;
}

- (double) signatureRadius {
	NCVerifyFittingContext(self.engine);
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	return ship ? ship->getSignatureRadius() : 0;
}

- (double) mass {
	NCVerifyFittingContext(self.engine);
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	return ship ? ship->getMass() : 0;
}

- (double) volume {
	NCVerifyFittingContext(self.engine);
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	return ship ? ship->getVolume() : 0;
}

- (double) agility {
	NCVerifyFittingContext(self.engine);
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	return ship ? ship->getAgility() : 0;
}

- (double) maxVelocityInOrbit:(double) orbit {
	NCVerifyFittingContext(self.engine);
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	return ship ? ship->getMaxVelocityInOrbit(orbit) : 0;
}

- (double) orbitRadiusWithTransverseVelocity:(double) velocity {
	NCVerifyFittingContext(self.engine);
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	return ship ? ship->getOrbitRadiusWithTransverseVelocity(velocity) : 0;
}

- (double) orbitRadiusWithAngularVelocity:(double) velocity {
	NCVerifyFittingContext(self.engine);
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	return ship ? ship->getOrbitRadiusWithAngularVelocity(velocity) : 0;
}

//MARK: Targeting

- (NSInteger) maxTargets {
	NCVerifyFittingContext(self.engine);
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	return ship ? ship->getMaxTargets() : 0;
}

- (double) maxTargetRange {
	NCVerifyFittingContext(self.engine);
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	return ship ? ship->getMaxTargetRange() : 0;
}

- (double) scanStrength {
	NCVerifyFittingContext(self.engine);
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	return ship ? ship->getScanStrength() : 0;
}

- (NCFittingScanType) scanType {
	NCVerifyFittingContext(self.engine);
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	return ship ? static_cast<NCFittingScanType>(ship->getScanType()) : NCFittingScanTypeRadar;
}

- (double) probeSize {
	NCVerifyFittingContext(self.engine);
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	return ship ? ship->getProbeSize() : 0;
}

- (double) scanResolution {
	NCVerifyFittingContext(self.engine);
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	return ship ? ship->getScanResolution() : 0;
}

//MARK: Drones

- (NSInteger) droneSquadronLimit:(NCFittingFighterSquadron) squadron {
	NCVerifyFittingContext(self.engine);
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	return ship ? ship->getDroneSquadronLimit(static_cast<dgmpp::Drone::FighterSquadron>(squadron)) : 0;
}

- (NSInteger) droneSquadronUsed:(NCFittingFighterSquadron) squadron {
	NCVerifyFittingContext(self.engine);
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	return ship ? ship->getDroneSquadronUsed(static_cast<dgmpp::Drone::FighterSquadron>(squadron)) : 0;
}

- (NSInteger) totalFighterLaunchTubes {
	NCVerifyFittingContext(self.engine);
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	return ship ? ship->getTotalFighterLaunchTubes() : 0;
}

- (NSInteger) fighterLaunchTubesUsed {
	NCVerifyFittingContext(self.engine);
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	return ship ? ship->getFighterLaunchTubesUsed() : 0;
}

@end
