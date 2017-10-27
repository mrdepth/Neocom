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
	return module ? static_cast<NCFittingModuleSlot>(module->getSlot()) : NCFittingModuleSlotUnknown;
}

- (NCFittingModuleHardpoint) hardpoint {
	NCVerifyFittingContext(self.engine);
	auto module = std::dynamic_pointer_cast<dgmpp::Module>(self.item);
	return module ? static_cast<NCFittingModuleHardpoint>(module->getHardpoint()) : NCFittingModuleHardpointNone;
}

- (NSInteger) socket {
	NCVerifyFittingContext(self.engine);
	auto module = std::dynamic_pointer_cast<dgmpp::Module>(self.item);
	return module ? module->getSocket() : 0;
}

- (NCFittingModuleState) state {
	NCVerifyFittingContext(self.engine);
	auto module = std::dynamic_pointer_cast<dgmpp::Module>(self.item);
	return module ? static_cast<NCFittingModuleState>(module->getState()) : NCFittingModuleStateUnknown;
}

- (NCFittingModuleState) preferredState {
	NCVerifyFittingContext(self.engine);
	auto module = std::dynamic_pointer_cast<dgmpp::Module>(self.item);
	return module ? static_cast<NCFittingModuleState>(module->getPreferredState()) : NCFittingModuleStateUnknown;
}

- (void) setState:(NCFittingModuleState)state {
	NCVerifyFittingContext(self.engine);
	auto module = std::dynamic_pointer_cast<dgmpp::Module>(self.item);
	if (module) {
		module->setState(static_cast<dgmpp::Module::State>(state));
		[self.engine updateWithItem: self];
	}
}

- (BOOL) isDummy {
	auto module = std::dynamic_pointer_cast<dgmpp::Module>(self.item);
	return module ? module->isDummy() : NO;
}

- (BOOL) canHaveState:(NCFittingModuleState)state {
	NCVerifyFittingContext(self.engine);
	auto module = std::dynamic_pointer_cast<dgmpp::Module>(self.item);
	return module ? module->canHaveState(static_cast<dgmpp::Module::State>(state)) : NO;
}

- (nullable NCFittingCharge*) charge {
	NCVerifyFittingContext(self.engine);
	auto module = std::dynamic_pointer_cast<dgmpp::Module>(self.item);
	return module ? (module->getCharge() ? (NCFittingCharge*) [NCFittingItem item:module->getCharge() withEngine:self.engine] : nil) : nil;
}

- (void) setCharge:(NCFittingCharge *)charge {
	NCVerifyFittingContext(self.engine);
	auto module = std::dynamic_pointer_cast<dgmpp::Module>(self.item);
	if (module) {
		charge.item = module->setCharge(static_cast<dgmpp::TypeID>(charge.typeID));
		charge.engine = self.engine;
		[self.engine updateWithItem: self];
	}
}

- (nonnull NSIndexSet*) chargeGroups {
	NCVerifyFittingContext(self.engine);
	auto module = std::dynamic_pointer_cast<dgmpp::Module>(self.item);
	if (module) {
		NSMutableIndexSet* set = [NSMutableIndexSet new];
		for (auto groupID: module->getChargeGroups()) {
			[set addIndex: static_cast<NSInteger>(groupID)];
		}
		return set;
	}
	else {
		return [NSIndexSet new];
	}
}

- (NSInteger) chargeSize {
	NCVerifyFittingContext(self.engine);
	auto module = std::dynamic_pointer_cast<dgmpp::Module>(self.item);
	return module ? module->getChargeSize() : 0;
}

- (BOOL) requireTarget {
	NCVerifyFittingContext(self.engine);
	auto module = std::dynamic_pointer_cast<dgmpp::Module>(self.item);
	return module ? module->requireTarget() : NO;
}

- (NCFittingShip*) target {
	NCVerifyFittingContext(self.engine);
	auto module = std::dynamic_pointer_cast<dgmpp::Module>(self.item);
	return module ? (module->getTarget() ? (NCFittingShip*) [NCFittingItem item:module->getTarget() withEngine:self.engine] : nil) : nil;
}

- (void) setTarget:(NCFittingShip *)target {
	NCVerifyFittingContext(self.engine);
	auto module = std::dynamic_pointer_cast<dgmpp::Module>(self.item);
	if (module) {
		if (!target)
			module->clearTarget();
		else
			module->setTarget(std::dynamic_pointer_cast<dgmpp::Ship>(target.item));
		[self.engine updateWithItem: self];
	}
}


- (double) reloadTime {
	NCVerifyFittingContext(self.engine);
	auto module = std::dynamic_pointer_cast<dgmpp::Module>(self.item);
	return module ? module->getReloadTime() : 0;
}

- (double) cycleTime {
	NCVerifyFittingContext(self.engine);
	auto module = std::dynamic_pointer_cast<dgmpp::Module>(self.item);
	return module ? module->getCycleTime() : 0;
}

- (double) rawCycleTime {
	NCVerifyFittingContext(self.engine);
	auto module = std::dynamic_pointer_cast<dgmpp::Module>(self.item);
	return module ? module->getRawCycleTime() : 0;
}

- (BOOL) factorReload {
	NCVerifyFittingContext(self.engine);
	auto module = std::dynamic_pointer_cast<dgmpp::Module>(self.item);
	return module ? module->factorReload() : 0;
}

- (void) setFactorReload:(BOOL)factorReload {
	NCVerifyFittingContext(self.engine);
	auto module = std::dynamic_pointer_cast<dgmpp::Module>(self.item);
	if (module) {
		module->setFactorReload(factorReload);
		[self.engine updateWithItem: self];
	}
}

- (NSInteger) charges {
	NCVerifyFittingContext(self.engine);
	auto module = std::dynamic_pointer_cast<dgmpp::Module>(self.item);
	return module ? module->getCharges() : 0;
}

- (NSInteger) shots {
	NCVerifyFittingContext(self.engine);
	auto module = std::dynamic_pointer_cast<dgmpp::Module>(self.item);
	return module ? module->getShots() : 0;
}

- (double) capUse {
	NCVerifyFittingContext(self.engine);
	auto module = std::dynamic_pointer_cast<dgmpp::Module>(self.item);
	return module ? module->getCapUse() : 0;
}

- (double) cpuUse {
	NCVerifyFittingContext(self.engine);
	auto module = std::dynamic_pointer_cast<dgmpp::Module>(self.item);
	return module ? module->getCpuUse() : 0;
}

- (double) powerGridUse {
	NCVerifyFittingContext(self.engine);
	auto module = std::dynamic_pointer_cast<dgmpp::Module>(self.item);
	return module ? module->getPowerGridUse() : 0;
}

- (double) calibrationUse {
	NCVerifyFittingContext(self.engine);
	auto module = std::dynamic_pointer_cast<dgmpp::Module>(self.item);
	return module ? module->getCalibrationUse() : 0;
}

- (NCFittingDamage) dps {
	NCVerifyFittingContext(self.engine);
	auto module = std::dynamic_pointer_cast<dgmpp::Module>(self.item);
	NCFittingDamage result;
	
	if (module) {
		auto damage = module->getDps();

		result.em = damage.emAmount;
		result.thermal = damage.thermalAmount;
		result.kinetic = damage.kineticAmount;
		result.explosive = damage.explosiveAmount;
	}
	
	return result;
}

- (NCFittingDamage) volley {
	NCVerifyFittingContext(self.engine);
	auto module = std::dynamic_pointer_cast<dgmpp::Module>(self.item);
	NCFittingDamage result;
	
	if (module) {
		auto damage = module->getVolley();

		result.em = damage.emAmount;
		result.thermal = damage.thermalAmount;
		result.kinetic = damage.kineticAmount;
		result.explosive = damage.explosiveAmount;
	}
	
	return result;
}

- (NCFittingDamage) dpsWithTarget:(NCFittingHostileTarget) target {
	NCVerifyFittingContext(self.engine);
	auto module = std::dynamic_pointer_cast<dgmpp::Module>(self.item);
	NCFittingDamage result;
	
	if (module) {
		dgmpp::HostileTarget hostileTarget(target.range, target.angularVelocity, target.signature, target.velocity);
		auto damage = module->getDps(hostileTarget);
		
		result.em = damage.emAmount;
		result.thermal = damage.thermalAmount;
		result.kinetic = damage.kineticAmount;
		result.explosive = damage.explosiveAmount;
	}
	
	return result;
}

- (double) maxRange {
	NCVerifyFittingContext(self.engine);
	auto module = std::dynamic_pointer_cast<dgmpp::Module>(self.item);
	return module ? module->getMaxRange() : 0;
}

- (double) falloff {
	NCVerifyFittingContext(self.engine);
	auto module = std::dynamic_pointer_cast<dgmpp::Module>(self.item);
	return module ? module->getFalloff() : 0;
}

- (double) accuracyScore {
	NCVerifyFittingContext(self.engine);
	auto module = std::dynamic_pointer_cast<dgmpp::Module>(self.item);
	return module ? module->getAccuracyScore() : 0;
}

- (double) signatureResolution {
	NCVerifyFittingContext(self.engine);
	auto module = std::dynamic_pointer_cast<dgmpp::Module>(self.item);
	return module ? module->getSignatureResolution() : 0;
}

- (double) lifeTime {
	NCVerifyFittingContext(self.engine);
	auto module = std::dynamic_pointer_cast<dgmpp::Module>(self.item);
	return module ? module->getLifeTime() : 0;
}

- (BOOL) isEnabled {
	NCVerifyFittingContext(self.engine);
	auto module = std::dynamic_pointer_cast<dgmpp::Module>(self.item);
	return module ? module->isEnabled() : NO;
}

- (double) miningYield {
	NCVerifyFittingContext(self.engine);
	auto module = std::dynamic_pointer_cast<dgmpp::Module>(self.item);
	return module ? module->getMiningYield() : 0;
}

- (BOOL) isAssistance {
	NCVerifyFittingContext(self.engine);
	auto module = std::dynamic_pointer_cast<dgmpp::Module>(self.item);
	return module ? module->isAssistance() : NO;
}

- (BOOL) isOffensive {
	NCVerifyFittingContext(self.engine);
	auto module = std::dynamic_pointer_cast<dgmpp::Module>(self.item);
	return module ? module->isOffensive() : NO;
}

- (double) angularVelocityWithTargetSignature:(double) targetSignature {
	return [self angularVelocityWithTargetSignature:targetSignature hitChance:0.75];
}

- (double) angularVelocityWithTargetSignature:(double) targetSignature hitChance:(double) hitChance NS_SWIFT_NAME(angularVelocity(targetSignature:hitChance:)) {
	NCVerifyFittingContext(self.engine);
	auto module = std::dynamic_pointer_cast<dgmpp::Module>(self.item);
	return module ? module->getAngularVelocity(targetSignature, hitChance) : 0;
}

- (NCFittingAccuracy) accuracyWithTargetSignature:(double) targetSignature {
	return [self accuracyWithTargetSignature:targetSignature hitChance:0.75];
}

- (NCFittingAccuracy) accuracyWithTargetSignature:(double) targetSignature hitChance:(double) hitChance {
	NCVerifyFittingContext(self.engine);
	auto module = std::dynamic_pointer_cast<dgmpp::Module>(self.item);
	if (module) {
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
			return NCFittingAccuracyLow;
	}
	else {
		return NCFittingAccuracyNone;
	}
}


@end
