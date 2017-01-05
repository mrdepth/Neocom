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

- (nonnull instancetype) initWithTypeID:(NSInteger) typeID {
	if (self = [super init]) {
		_typeID = typeID;
	}
	return self;
}

- (NSInteger) typeID {
	return self.item ? [super typeID] : _typeID;
}

- (nullable NCFittingModule*) addModuleWithTypeID:(NSInteger) typeID {
	return [self addModuleWithTypeID:typeID forced:false];
}

- (nullable NCFittingModule*) addModuleWithTypeID:(NSInteger) typeID forced:(BOOL) forced {
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	auto module = ship->addModule(static_cast<dgmpp::TypeID>(typeID), forced);
	return module ? [[NCFittingModule alloc] initWithItem:module] : nil;
}

- (nullable NCFittingModule*) replaceModule:(nonnull NCFittingModule*) module withTypeID:(NSInteger) typeID {
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	auto result = ship->replaceModule(std::dynamic_pointer_cast<dgmpp::Module>(module.item), static_cast<dgmpp::TypeID>(typeID));
	return result ? [[NCFittingModule alloc] initWithItem:result] : nil;
}

- (void) removeModule:(nonnull NCFittingModule*) module {
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	ship->removeModule(std::dynamic_pointer_cast<dgmpp::Module>(module.item));
}

- (nonnull NSArray<NCFittingModule*>*) modulesWithSlot:(NCFittingModuleSlot) slot {
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	dgmpp::ModulesList modules;
	ship->getModules(static_cast<dgmpp::Module::Slot>(slot), std::inserter(modules, modules.begin()));
	NSMutableArray* array = [NSMutableArray new];
	for (auto i: modules) {
		[array addObject:[[NCFittingModule alloc] initWithItem:i]];
	}
	return array;
}

- (nullable NCFittingDrone*) addDroneWithTypeID:(NSInteger) typeID {
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	auto drone = ship->addDrone(static_cast<dgmpp::TypeID>(typeID));
	return drone ? [[NCFittingDrone alloc] initWithItem:drone] : nil;
}

- (void) removeDrone:(nonnull NCFittingDrone*) drone {
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	ship->removeDrone(std::dynamic_pointer_cast<dgmpp::Drone>(drone.item));
}

//MARK: Calculations

- (NSInteger) totalSlots:(NCFittingModuleSlot) slot {
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	return ship->getNumberOfSlots(static_cast<dgmpp::Module::Slot>(slot));
}

- (NSInteger) freeSlots:(NCFittingModuleSlot) slot {
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	return ship->getFreeSlots(static_cast<dgmpp::Module::Slot>(slot));
}

- (NSInteger) usedSlots:(NCFittingModuleSlot) slot {
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	return ship->getUsedSlots(static_cast<dgmpp::Module::Slot>(slot));
}

- (NSInteger) totalHardpoints:(NCFittingModuleHardpoint) hardpoint {
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	return ship->getNumberOfHardpoints(static_cast<dgmpp::Module::Hardpoint>(hardpoint));
}

- (NSInteger) freeHardpoints:(NCFittingModuleHardpoint) hardpoint {
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	return ship->getFreeHardpoints(static_cast<dgmpp::Module::Hardpoint>(hardpoint));
}

- (NSInteger) usedHardpoints:(NCFittingModuleHardpoint) hardpoint {
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	return ship->getUsedHardpoints(static_cast<dgmpp::Module::Hardpoint>(hardpoint));
}

- (double) capacity {
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	return ship->getCapacity();
}

- (double) oreHoldCapacity {
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	return ship->getOreHoldCapacity();
}

- (double) calibrationUsed {
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	return ship->getCalibrationUsed();
}

- (double) totalCalibration {
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	return ship->getTotalCalibration();
}

- (double) powerGridUsed {
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	return ship->getPowerGridUsed();
}

- (double) totalPowerGrid {
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	return ship->getTotalPowerGrid();
}

- (double) cpuUsed {
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	return ship->getCpuUsed();
}

- (double) totalCPU {
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	return ship->getTotalCpu();
}

- (double) droneBandwidthUsed {
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	return ship->getDroneBandwidthUsed();
}

- (double) totalDroneBandwidth {
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	return ship->getTotalDroneBandwidth();
}

- (double) droneBayUsed {
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	return ship->getDroneBayUsed();
}

- (double) totalDroneBay {
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	return ship->getTotalDroneBay();
}

- (double) fighterHangarUsed {
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	return ship->getFighterHangarUsed();
}

- (double) totalFighterHangar {
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	return ship->getTotalFighterHangar();
}

//MARK: Capacitor

- (double) capCapacity {
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	return ship->getCapCapacity();
}

- (BOOL) isCapStable {
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	return ship->isCapStable();
}

- (NSTimeInterval) capLastsTime {
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	return ship->getCapLastsTime();
}

- (double) capStableLevel {
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	return ship->getCapStableLevel();
}

- (double) capUsed {
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	return ship->getCapUsed();
}

- (double) capRecharge {
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	return ship->getCapRecharge();
}

//MARK: Tank

- (NCFittingResistances) resistances {
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	auto resistances = ship->getResistances();
	NCFittingResistances result;

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

	return result;
}

- (NCFittingTank) tank {
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	auto tank = ship->getTank();
	NCFittingTank result;
	
	result.passiveShield = tank.passiveShield;
	result.shieldRepair = tank.shieldRepair;
	result.armorRepair = tank.armorRepair;
	result.hullRepair = tank.hullRepair;
	
	return result;
}

- (NCFittingTank) effectiveTank {
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	auto tank = ship->getEffectiveTank();
	NCFittingTank result;
	
	result.passiveShield = tank.passiveShield;
	result.shieldRepair = tank.shieldRepair;
	result.armorRepair = tank.armorRepair;
	result.hullRepair = tank.hullRepair;
	
	return result;
}

- (NCFittingTank) sustainableTank {
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	auto tank = ship->getSustainableTank();
	NCFittingTank result;
	
	result.passiveShield = tank.passiveShield;
	result.shieldRepair = tank.shieldRepair;
	result.armorRepair = tank.armorRepair;
	result.hullRepair = tank.hullRepair;
	
	return result;
}

- (NCFittingTank) effectiveSustainableTank {
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	auto tank = ship->getEffectiveSustainableTank();
	NCFittingTank result;
	
	result.passiveShield = tank.passiveShield;
	result.shieldRepair = tank.shieldRepair;
	result.armorRepair = tank.armorRepair;
	result.hullRepair = tank.hullRepair;
	
	return result;
}

- (NCFittingHitPoints) hitPoints {
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	auto hitPoints = ship->getHitPoints();
	NCFittingHitPoints result;
	
	result.shield = hitPoints.shield;
	result.armor = hitPoints.armor;
	result.hull = hitPoints.hull;
	
	return result;
}

- (NCFittingHitPoints) effectiveHitPoints {
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	auto hitPoints = ship->getEffectiveHitPoints();
	NCFittingHitPoints result;
	
	result.shield = hitPoints.shield;
	result.armor = hitPoints.armor;
	result.hull = hitPoints.hull;
	
	return result;
}

- (double) shieldRecharge {
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	return ship->getShieldRecharge();
}

//MARK: DPS
- (NCFittingDamage) weaponDPS {
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	auto damage = ship->getWeaponDps();
	NCFittingDamage result;
	
	result.em = damage.emAmount;
	result.thermal = damage.thermalAmount;
	result.kinetic = damage.kineticAmount;
	result.explosive = damage.explosiveAmount;
	
	return result;
}

- (NCFittingDamage) weaponVolley {
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	auto damage = ship->getWeaponVolley();
	NCFittingDamage result;
	
	result.em = damage.emAmount;
	result.thermal = damage.thermalAmount;
	result.kinetic = damage.kineticAmount;
	result.explosive = damage.explosiveAmount;
	
	return result;
}

- (NCFittingDamage) weaponDPSWithTarget:(NCFittingHostileTarget) target {
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	dgmpp::HostileTarget hostileTarget(target.range, target.angularVelocity, target.signature, target.velocity);
	auto damage = ship->getWeaponDps(hostileTarget);
	NCFittingDamage result;
	
	result.em = damage.emAmount;
	result.thermal = damage.thermalAmount;
	result.kinetic = damage.kineticAmount;
	result.explosive = damage.explosiveAmount;
	
	return result;
}

- (NCFittingDamage) droneDPS {
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	auto damage = ship->getDroneDps();
	NCFittingDamage result;
	
	result.em = damage.emAmount;
	result.thermal = damage.thermalAmount;
	result.kinetic = damage.kineticAmount;
	result.explosive = damage.explosiveAmount;
	
	return result;
}

- (NCFittingDamage) droneVolley {
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	auto damage = ship->getDroneVolley();
	NCFittingDamage result;
	
	result.em = damage.emAmount;
	result.thermal = damage.thermalAmount;
	result.kinetic = damage.kineticAmount;
	result.explosive = damage.explosiveAmount;
	
	return result;
}

- (NCFittingDamage) droneDPSWithTarget:(NCFittingHostileTarget) target {
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	dgmpp::HostileTarget hostileTarget(target.range, target.angularVelocity, target.signature, target.velocity);
	auto damage = ship->getDroneDps(hostileTarget);
	NCFittingDamage result;
	
	result.em = damage.emAmount;
	result.thermal = damage.thermalAmount;
	result.kinetic = damage.kineticAmount;
	result.explosive = damage.explosiveAmount;
	
	return result;
}

//MARK: Mobility

- (double) alignTime {
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	return ship->getAlignTime();
}

- (double) warpSpeed {
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	return ship->getWarpSpeed();
}

- (double) maxWarpDistance {
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	return ship->getMaxWarpDistance();
}

- (double) velocity {
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	return ship->getVelocity();
}

- (double) signatureRadius {
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	return ship->getSignatureRadius();
}

- (double) mass {
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	return ship->getMass();
}

- (double) volume {
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	return ship->getVolume();
}

- (double) agility {
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	return ship->getAgility();
}

- (double) maxVelocityInOrbit:(double) orbit {
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	return ship->getMaxVelocityInOrbit(orbit);
}

- (double) orbitRadiusWithTransverseVelocity:(double) velocity {
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	return ship->getOrbitRadiusWithTransverseVelocity(velocity);
}

- (double) orbitRadiusWithAngularVelocity:(double) velocity {
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	return ship->getOrbitRadiusWithAngularVelocity(velocity);
}

//MARK: Targeting

- (NSInteger) maxTargets {
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	return ship->getMaxTargets();
}

- (double) maxTargetRange {
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	return ship->getMaxTargetRange();
}

- (double) scanStrength {
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	return ship->getScanStrength();
}

- (NCFittingScanType) scanType {
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	return static_cast<NCFittingScanType>(ship->getScanType());
}

- (double) probeSize {
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	return ship->getProbeSize();
}

- (double) scanResolution {
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	return ship->getScanResolution();
}

//MARK: Drones

- (NSInteger) droneSquadronLimit:(NCFittingFighterSquadron) squadron {
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	return ship->getDroneSquadronLimit(static_cast<dgmpp::Drone::FighterSquadron>(squadron));
}

- (NSInteger) droneSquadronUsed:(NCFittingFighterSquadron) squadron {
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	return ship->getDroneSquadronUsed(static_cast<dgmpp::Drone::FighterSquadron>(squadron));
}

- (NSInteger) totalFighterLaunchTubes {
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	return ship->getTotalFighterLaunchTubes();
}

- (NSInteger) fighterLaunchTubesUsed {
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	return ship->getFighterLaunchTubesUsed();
}

@end
