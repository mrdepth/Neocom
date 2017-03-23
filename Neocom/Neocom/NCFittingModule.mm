//
//  NCFittingModule.m
//  Neocom
//
//  Created by Artem Shimanski on 04.01.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

#import "NCFittingModule.h"
#import "NCFittingCharge.h"
#import "NCFittingProtected.h"

@implementation NCFittingModule

- (NCFittingModuleSlot) slot {
	NCVerifyFittingContext(self.engine);
	auto module = std::dynamic_pointer_cast<dgmpp::Module>(self.item);
	return static_cast<NCFittingModuleSlot>(module->getSlot());
}

- (NCFittingModuleHardpoint) hardpoint {
	NCVerifyFittingContext(self.engine);
	auto module = std::dynamic_pointer_cast<dgmpp::Module>(self.item);
	return static_cast<NCFittingModuleHardpoint>(module->getHardpoint());
}

- (NSInteger) socket {
	NCVerifyFittingContext(self.engine);
	auto module = std::dynamic_pointer_cast<dgmpp::Module>(self.item);
	return module->getSocket();
}

- (NCFittingModuleState) state {
	NCVerifyFittingContext(self.engine);
	auto module = std::dynamic_pointer_cast<dgmpp::Module>(self.item);
	return static_cast<NCFittingModuleState>(module->getState());
}

- (NCFittingModuleState) preferredState {
	NCVerifyFittingContext(self.engine);
	auto module = std::dynamic_pointer_cast<dgmpp::Module>(self.item);
	return static_cast<NCFittingModuleState>(module->getPreferredState());
}

- (void) setPreferredState:(NCFittingModuleState)preferredState {
	NCVerifyFittingContext(self.engine);
	auto module = std::dynamic_pointer_cast<dgmpp::Module>(self.item);
	module->setPreferredState(static_cast<dgmpp::Module::State>(preferredState));
	[self.engine updateWithItem: self];
}

- (BOOL) isDummy {
	auto module = std::dynamic_pointer_cast<dgmpp::Module>(self.item);
	return module->isDummy();
}

- (BOOL) canHaveState:(NCFittingModuleState)state {
	NCVerifyFittingContext(self.engine);
	auto module = std::dynamic_pointer_cast<dgmpp::Module>(self.item);
	return module->canHaveState(static_cast<dgmpp::Module::State>(state));
}

- (nullable NCFittingCharge*) charge {
	NCVerifyFittingContext(self.engine);
	auto module = std::dynamic_pointer_cast<dgmpp::Module>(self.item);
	return module->getCharge() ? (NCFittingCharge*) [NCFittingItem item:module->getCharge() withEngine:self.engine] : nil;
}

- (void) setCharge:(NCFittingCharge *)charge {
	NCVerifyFittingContext(self.engine);
	auto module = std::dynamic_pointer_cast<dgmpp::Module>(self.item);
	charge.item = module->setCharge(static_cast<dgmpp::TypeID>(charge.typeID));
	[self.engine updateWithItem: self];
}

- (NSIndexSet*) chargeGroups {
	NCVerifyFittingContext(self.engine);
	auto module = std::dynamic_pointer_cast<dgmpp::Module>(self.item);
	NSMutableIndexSet* set = [NSMutableIndexSet new];
	for (auto groupID: module->getChargeGroups()) {
		[set addIndex:groupID];
	}
	return set;
}

- (NSInteger) chargeSize {
	NCVerifyFittingContext(self.engine);
	auto module = std::dynamic_pointer_cast<dgmpp::Module>(self.item);
	return module->getChargeSize();
}

- (BOOL) requireTarget {
	NCVerifyFittingContext(self.engine);
	auto module = std::dynamic_pointer_cast<dgmpp::Module>(self.item);
	return module->requireTarget();
}

- (NCFittingShip*) target {
	NCVerifyFittingContext(self.engine);
	auto module = std::dynamic_pointer_cast<dgmpp::Module>(self.item);
	return module->getTarget() ? (NCFittingShip*) [NCFittingItem item:module->getTarget() withEngine:self.engine] : nil;
}

- (void) setTarget:(NCFittingShip *)target {
	NCVerifyFittingContext(self.engine);
	auto module = std::dynamic_pointer_cast<dgmpp::Module>(self.item);
	if (!target)
		module->clearTarget();
	else
		module->setTarget(std::dynamic_pointer_cast<dgmpp::Ship>(target.item));
	[self.engine updateWithItem: self];
}


- (double) reloadTime {
	NCVerifyFittingContext(self.engine);
	auto module = std::dynamic_pointer_cast<dgmpp::Module>(self.item);
	return module->getReloadTime();
}

- (double) cycleTime {
	NCVerifyFittingContext(self.engine);
	auto module = std::dynamic_pointer_cast<dgmpp::Module>(self.item);
	return module->getCycleTime();
}

- (double) rawCycleTime {
	NCVerifyFittingContext(self.engine);
	auto module = std::dynamic_pointer_cast<dgmpp::Module>(self.item);
	return module->getRawCycleTime();
}

- (BOOL) factorReload {
	NCVerifyFittingContext(self.engine);
	auto module = std::dynamic_pointer_cast<dgmpp::Module>(self.item);
	return module->factorReload();
}

- (void) setFactorReload:(BOOL)factorReload {
	NCVerifyFittingContext(self.engine);
	auto module = std::dynamic_pointer_cast<dgmpp::Module>(self.item);
	module->setFactorReload(factorReload);
	[self.engine updateWithItem: self];
}

- (NSInteger) charges {
	NCVerifyFittingContext(self.engine);
	auto module = std::dynamic_pointer_cast<dgmpp::Module>(self.item);
	return module->getCharges();
}

- (NSInteger) shots {
	NCVerifyFittingContext(self.engine);
	auto module = std::dynamic_pointer_cast<dgmpp::Module>(self.item);
	return module->getShots();
}

- (double) capUse {
	NCVerifyFittingContext(self.engine);
	auto module = std::dynamic_pointer_cast<dgmpp::Module>(self.item);
	return module->getCapUse();
}

- (double) cpuUse {
	NCVerifyFittingContext(self.engine);
	auto module = std::dynamic_pointer_cast<dgmpp::Module>(self.item);
	return module->getCpuUse();
}

- (double) powerGridUse {
	NCVerifyFittingContext(self.engine);
	auto module = std::dynamic_pointer_cast<dgmpp::Module>(self.item);
	return module->getPowerGridUse();
}

- (double) calibrationUse {
	NCVerifyFittingContext(self.engine);
	auto module = std::dynamic_pointer_cast<dgmpp::Module>(self.item);
	return module->getCalibrationUse();
}

- (NCFittingDamage) dps {
	NCVerifyFittingContext(self.engine);
	auto module = std::dynamic_pointer_cast<dgmpp::Module>(self.item);
	auto damage = module->getDps();
	NCFittingDamage result;
	
	result.em = damage.emAmount;
	result.thermal = damage.thermalAmount;
	result.kinetic = damage.kineticAmount;
	result.explosive = damage.explosiveAmount;
	
	return result;
}

- (NCFittingDamage) volley {
	NCVerifyFittingContext(self.engine);
	auto module = std::dynamic_pointer_cast<dgmpp::Module>(self.item);
	auto damage = module->getVolley();
	NCFittingDamage result;
	
	result.em = damage.emAmount;
	result.thermal = damage.thermalAmount;
	result.kinetic = damage.kineticAmount;
	result.explosive = damage.explosiveAmount;
	
	return result;
}

- (NCFittingDamage) dpsWithTarget:(NCFittingHostileTarget) target {
	NCVerifyFittingContext(self.engine);
	auto module = std::dynamic_pointer_cast<dgmpp::Module>(self.item);
	dgmpp::HostileTarget hostileTarget(target.range, target.angularVelocity, target.signature, target.velocity);
	auto damage = module->getDps(hostileTarget);
	NCFittingDamage result;
	
	result.em = damage.emAmount;
	result.thermal = damage.thermalAmount;
	result.kinetic = damage.kineticAmount;
	result.explosive = damage.explosiveAmount;
	
	return result;
}

- (double) maxRange {
	NCVerifyFittingContext(self.engine);
	auto module = std::dynamic_pointer_cast<dgmpp::Module>(self.item);
	return module->getMaxRange();
}

- (double) falloff {
	NCVerifyFittingContext(self.engine);
	auto module = std::dynamic_pointer_cast<dgmpp::Module>(self.item);
	return module->getFalloff();
}

- (double) accuracyScore {
	NCVerifyFittingContext(self.engine);
	auto module = std::dynamic_pointer_cast<dgmpp::Module>(self.item);
	return module->getAccuracyScore();
}

- (double) signatureResolution {
	NCVerifyFittingContext(self.engine);
	auto module = std::dynamic_pointer_cast<dgmpp::Module>(self.item);
	return module->getSignatureResolution();
}

- (double) lifeTime {
	NCVerifyFittingContext(self.engine);
	auto module = std::dynamic_pointer_cast<dgmpp::Module>(self.item);
	return module->getLifeTime();
}

- (BOOL) isEnabled {
	NCVerifyFittingContext(self.engine);
	auto module = std::dynamic_pointer_cast<dgmpp::Module>(self.item);
	return module->isEnabled();
}

- (double) miningYield {
	NCVerifyFittingContext(self.engine);
	auto module = std::dynamic_pointer_cast<dgmpp::Module>(self.item);
	return module->getMiningYield();
}

- (double) angularVelocityWithTargetSignature:(double) targetSignature {
	return [self angularVelocityWithTargetSignature:targetSignature hitChance:0.75];
}

- (double) angularVelocityWithTargetSignature:(double) targetSignature hitChance:(double) hitChance NS_SWIFT_NAME(angularVelocity(targetSignature:hitChance:)) {
	NCVerifyFittingContext(self.engine);
	auto module = std::dynamic_pointer_cast<dgmpp::Module>(self.item);
	return module->getAngularVelocity(targetSignature, hitChance);
}

- (NCFittingAccuracy) accuracyWithTargetSignature:(double) targetSignature {
	return [self accuracyWithTargetSignature:targetSignature hitChance:0.75];
}

- (NCFittingAccuracy) accuracyWithTargetSignature:(double) targetSignature hitChance:(double) hitChance {
	NCVerifyFittingContext(self.engine);
	auto module = std::dynamic_pointer_cast<dgmpp::Module>(self.item);
	auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(module->getOwner());
	if (!ship || module->getAccuracyScore() <= 0)
		return NCFittingAccuracyNone;
	
	double optimal = module->getMaxRange();
	double falloff = module->getFalloff();
	double angularVelocity = [self angularVelocityWithTargetSignature:targetSignature hitChance:hitChance];
	double v0 = ship->getMaxVelocityInOrbit(optimal);
	double v1 = ship->getMaxVelocityInOrbit(optimal + falloff);
	if (angularVelocity * optimal > v0)
		return NCFittingAccuracyGood;
	else if (angularVelocity * (optimal + falloff) > v1)
		return NCFittingAccuracyAverage;
	else
		return
		NCFittingAccuracyLow;
}


@end
