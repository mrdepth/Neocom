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

- (nonnull NSArray<NCFittingModule*>*) modules {
	NCVerifyFittingContext(self.engine);
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	dgmpp::ModulesList modules = ship->getModules(true);
	NSMutableArray* array = [NSMutableArray new];
	for (auto i: modules) {
		[array addObject:(NCFittingModule*) [NCFittingItem item:i withEngine:self.engine]];
	}
	return array;
}

- (nonnull NSArray<NCFittingDrone*>*) drones {
	NCVerifyFittingContext(self.engine);
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	NSMutableArray* array = [NSMutableArray new];
	for (auto i: ship->getDrones()) {
		[array addObject:(NCFittingDrone*) [NCFittingItem item:i withEngine:self.engine]];
	}
	return array;
}

- (NCFittingDamage) damagePattern {
	NCVerifyFittingContext(self.engine);
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	auto damage = ship->getDamagePattern();
	NCFittingDamage result;
	
	result.em = damage.emAmount;
	result.thermal = damage.thermalAmount;
	result.kinetic = damage.kineticAmount;
	result.explosive = damage.explosiveAmount;
	
	return result;
}

- (void) setDamagePattern:(NCFittingDamage)damagePattern {
	NCVerifyFittingContext(self.engine);
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	dgmpp::DamagePattern result;
	result.emAmount = damagePattern.em;
	result.thermalAmount = damagePattern.thermal;
	result.kineticAmount = damagePattern.kinetic;
	result.explosiveAmount = damagePattern.explosive;
	ship->setDamagePattern(result);
	[self.engine didUpdate];
}

- (nullable NCFittingModule*) addModuleWithTypeID:(NSInteger) typeID {
	return [self addModuleWithTypeID:typeID forced:false socket:-1];
}

- (nullable NCFittingModule*) addModuleWithTypeID:(NSInteger) typeID forced:(BOOL) forced socket:(NSInteger) socket {
	NCVerifyFittingContext(self.engine);
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	auto module = ship->addModule(static_cast<dgmpp::TypeID>(typeID), forced, static_cast<int>(socket));
	[self.engine didUpdate];
	return module ? (NCFittingModule*) [NCFittingItem item:module withEngine:self.engine] : nil;
}

- (nullable NCFittingModule*) replaceModule:(nonnull NCFittingModule*) module withTypeID:(NSInteger) typeID {
	NCVerifyFittingContext(self.engine);
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	auto result = ship->replaceModule(std::dynamic_pointer_cast<dgmpp::Module>(module.item), static_cast<dgmpp::TypeID>(typeID));
	[self.engine didUpdate];
	return result ? (NCFittingModule*) [NCFittingItem item:result withEngine:self.engine] : nil;
}

- (void) removeModule:(nonnull NCFittingModule*) module {
	NCVerifyFittingContext(self.engine);
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	ship->removeModule(std::dynamic_pointer_cast<dgmpp::Module>(module.item));
	[self.engine didUpdate];
}

- (nonnull NSArray<NCFittingModule*>*) modulesWithSlot:(NCFittingModuleSlot) slot {
	NCVerifyFittingContext(self.engine);
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	dgmpp::ModulesList modules = ship->getModules(static_cast<dgmpp::Module::Slot>(slot), true);
	NSMutableArray* array = [NSMutableArray new];
	for (auto i: modules) {
		[array addObject:(NCFittingModule*) [NCFittingItem item:i withEngine:self.engine]];
	}
	return array;
}

- (nullable NCFittingDrone*) addDroneWithTypeID:(NSInteger) typeID {
	return [self addDroneWithTypeID:typeID squadronTag:-1];
}

- (nullable NCFittingDrone*) addDroneWithTypeID:(NSInteger) typeID squadronTag:(NSInteger) squadronTag {
	NCVerifyFittingContext(self.engine);
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	auto drone = ship->addDrone(static_cast<dgmpp::TypeID>(typeID), static_cast<int>(squadronTag));
	[self.engine didUpdate];
	return drone ? (NCFittingDrone*) [NCFittingItem item:drone withEngine:self.engine] : nil;
}

- (void) removeDrone:(nonnull NCFittingDrone*) drone {
	NCVerifyFittingContext(self.engine);
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	ship->removeDrone(std::dynamic_pointer_cast<dgmpp::Drone>(drone.item));
	[self.engine didUpdate];
}

//MARK: Calculations

- (NSInteger) totalSlots:(NCFittingModuleSlot) slot {
	NCVerifyFittingContext(self.engine);
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	return ship->getNumberOfSlots(static_cast<dgmpp::Module::Slot>(slot));
}

- (NSInteger) freeSlots:(NCFittingModuleSlot) slot {
	NCVerifyFittingContext(self.engine);
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	return ship->getFreeSlots(static_cast<dgmpp::Module::Slot>(slot));
}

- (NSInteger) usedSlots:(NCFittingModuleSlot) slot {
	NCVerifyFittingContext(self.engine);
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	return ship->getUsedSlots(static_cast<dgmpp::Module::Slot>(slot));
}

- (NSInteger) totalHardpoints:(NCFittingModuleHardpoint) hardpoint {
	NCVerifyFittingContext(self.engine);
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	return ship->getNumberOfHardpoints(static_cast<dgmpp::Module::Hardpoint>(hardpoint));
}

- (NSInteger) freeHardpoints:(NCFittingModuleHardpoint) hardpoint {
	NCVerifyFittingContext(self.engine);
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	return ship->getFreeHardpoints(static_cast<dgmpp::Module::Hardpoint>(hardpoint));
}

- (NSInteger) usedHardpoints:(NCFittingModuleHardpoint) hardpoint {
	NCVerifyFittingContext(self.engine);
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	return ship->getUsedHardpoints(static_cast<dgmpp::Module::Hardpoint>(hardpoint));
}

- (NSInteger) rigSize {
	NCVerifyFittingContext(self.engine);
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	return ship->getRigSize();
}

- (double) capacity {
	NCVerifyFittingContext(self.engine);
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	return ship->getCapacity();
}

- (double) oreHoldCapacity {
	NCVerifyFittingContext(self.engine);
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	return ship->getOreHoldCapacity();
}

- (double) calibrationUsed {
	NCVerifyFittingContext(self.engine);
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	return ship->getCalibrationUsed();
}

- (double) totalCalibration {
	NCVerifyFittingContext(self.engine);
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	return ship->getTotalCalibration();
}

- (double) powerGridUsed {
	NCVerifyFittingContext(self.engine);
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	return ship->getPowerGridUsed();
}

- (double) totalPowerGrid {
	NCVerifyFittingContext(self.engine);
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	return ship->getTotalPowerGrid();
}

- (double) cpuUsed {
	NCVerifyFittingContext(self.engine);
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	return ship->getCpuUsed();
}

- (double) totalCPU {
	NCVerifyFittingContext(self.engine);
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	return ship->getTotalCpu();
}

- (double) droneBandwidthUsed {
	NCVerifyFittingContext(self.engine);
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	return ship->getDroneBandwidthUsed();
}

- (double) totalDroneBandwidth {
	NCVerifyFittingContext(self.engine);
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	return ship->getTotalDroneBandwidth();
}

- (double) droneBayUsed {
	NCVerifyFittingContext(self.engine);
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	return ship->getDroneBayUsed();
}

- (double) totalDroneBay {
	NCVerifyFittingContext(self.engine);
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	return ship->getTotalDroneBay();
}

- (double) fighterHangarUsed {
	NCVerifyFittingContext(self.engine);
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	return ship->getFighterHangarUsed();
}

- (double) totalFighterHangar {
	NCVerifyFittingContext(self.engine);
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	return ship->getTotalFighterHangar();
}

//MARK: Capacitor

- (double) capCapacity {
	NCVerifyFittingContext(self.engine);
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	return ship->getCapCapacity();
}

- (BOOL) isCapStable {
	NCVerifyFittingContext(self.engine);
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	return ship->isCapStable();
}

- (NSTimeInterval) capLastsTime {
	NCVerifyFittingContext(self.engine);
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	return ship->getCapLastsTime();
}

- (double) capStableLevel {
	NCVerifyFittingContext(self.engine);
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	return ship->getCapStableLevel();
}

- (double) capUsed {
	NCVerifyFittingContext(self.engine);
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	return ship->getCapUsed();
}

- (double) capRecharge {
	NCVerifyFittingContext(self.engine);
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	return ship->getCapRecharge();
}

- (double) capRechargeTime {
	NCVerifyFittingContext(self.engine);
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	return ship->getCapRechargeTime();
}

//MARK: Tank

- (NCFittingResistances) resistances {
	NCVerifyFittingContext(self.engine);
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
	NCVerifyFittingContext(self.engine);
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
	NCVerifyFittingContext(self.engine);
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
	NCVerifyFittingContext(self.engine);
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
	NCVerifyFittingContext(self.engine);
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
	NCVerifyFittingContext(self.engine);
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	auto hitPoints = ship->getHitPoints();
	NCFittingHitPoints result;
	
	result.shield = hitPoints.shield;
	result.armor = hitPoints.armor;
	result.hull = hitPoints.hull;
	
	return result;
}

- (NCFittingHitPoints) effectiveHitPoints {
	NCVerifyFittingContext(self.engine);
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	auto hitPoints = ship->getEffectiveHitPoints();
	NCFittingHitPoints result;
	
	result.shield = hitPoints.shield;
	result.armor = hitPoints.armor;
	result.hull = hitPoints.hull;
	
	return result;
}

- (double) shieldRecharge {
	NCVerifyFittingContext(self.engine);
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	return ship->getShieldRecharge();
}

//MARK: DPS
- (NCFittingDamage) weaponDPS {
	NCVerifyFittingContext(self.engine);
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
	NCVerifyFittingContext(self.engine);
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
	NCVerifyFittingContext(self.engine);
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
	NCVerifyFittingContext(self.engine);
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
	NCVerifyFittingContext(self.engine);
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
	NCVerifyFittingContext(self.engine);
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
	NCVerifyFittingContext(self.engine);
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	return ship->getAlignTime();
}

- (double) warpSpeed {
	NCVerifyFittingContext(self.engine);
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	return ship->getWarpSpeed();
}

- (double) maxWarpDistance {
	NCVerifyFittingContext(self.engine);
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	return ship->getMaxWarpDistance();
}

- (double) velocity {
	NCVerifyFittingContext(self.engine);
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	return ship->getVelocity();
}

- (double) signatureRadius {
	NCVerifyFittingContext(self.engine);
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	return ship->getSignatureRadius();
}

- (double) mass {
	NCVerifyFittingContext(self.engine);
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	return ship->getMass();
}

- (double) volume {
	NCVerifyFittingContext(self.engine);
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	return ship->getVolume();
}

- (double) agility {
	NCVerifyFittingContext(self.engine);
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	return ship->getAgility();
}

- (double) maxVelocityInOrbit:(double) orbit {
	NCVerifyFittingContext(self.engine);
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	return ship->getMaxVelocityInOrbit(orbit);
}

- (double) orbitRadiusWithTransverseVelocity:(double) velocity {
	NCVerifyFittingContext(self.engine);
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	return ship->getOrbitRadiusWithTransverseVelocity(velocity);
}

- (double) orbitRadiusWithAngularVelocity:(double) velocity {
	NCVerifyFittingContext(self.engine);
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	return ship->getOrbitRadiusWithAngularVelocity(velocity);
}

//MARK: Targeting

- (NSInteger) maxTargets {
	NCVerifyFittingContext(self.engine);
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	return ship->getMaxTargets();
}

- (double) maxTargetRange {
	NCVerifyFittingContext(self.engine);
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	return ship->getMaxTargetRange();
}

- (double) scanStrength {
	NCVerifyFittingContext(self.engine);
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	return ship->getScanStrength();
}

- (NCFittingScanType) scanType {
	NCVerifyFittingContext(self.engine);
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	return static_cast<NCFittingScanType>(ship->getScanType());
}

- (double) probeSize {
	NCVerifyFittingContext(self.engine);
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	return ship->getProbeSize();
}

- (double) scanResolution {
	NCVerifyFittingContext(self.engine);
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	return ship->getScanResolution();
}

//MARK: Drones

- (NSInteger) droneSquadronLimit:(NCFittingFighterSquadron) squadron {
	NCVerifyFittingContext(self.engine);
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	return ship->getDroneSquadronLimit(static_cast<dgmpp::Drone::FighterSquadron>(squadron));
}

- (NSInteger) droneSquadronUsed:(NCFittingFighterSquadron) squadron {
	NCVerifyFittingContext(self.engine);
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	return ship->getDroneSquadronUsed(static_cast<dgmpp::Drone::FighterSquadron>(squadron));
}

- (NSInteger) totalFighterLaunchTubes {
	NCVerifyFittingContext(self.engine);
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	return ship->getTotalFighterLaunchTubes();
}

- (NSInteger) fighterLaunchTubesUsed {
	NCVerifyFittingContext(self.engine);
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(self.item);
	return ship->getFighterLaunchTubesUsed();
}

@end
