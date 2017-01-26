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
	auto module = std::dynamic_pointer_cast<dgmpp::Module>(self.item);
	return static_cast<NCFittingModuleSlot>(module->getSlot());
}

- (NCFittingModuleHardpoint) hardpoint {
	auto module = std::dynamic_pointer_cast<dgmpp::Module>(self.item);
	return static_cast<NCFittingModuleHardpoint>(module->getHardpoint());
}

- (NCFittingModuleState) state {
	auto module = std::dynamic_pointer_cast<dgmpp::Module>(self.item);
	return static_cast<NCFittingModuleState>(module->getState());
}

- (NCFittingModuleState) preferredState {
	auto module = std::dynamic_pointer_cast<dgmpp::Module>(self.item);
	return static_cast<NCFittingModuleState>(module->getPreferredState());
}

- (NSInteger) socket {
	auto module = std::dynamic_pointer_cast<dgmpp::Module>(self.item);
	return module->getSocket();
}

- (void) setSocket:(NSInteger)socket {
	auto module = std::dynamic_pointer_cast<dgmpp::Module>(self.item);
	module->setSocket(static_cast<int>(socket));
}

- (void) setPreferredState:(NCFittingModuleState)preferredState {
	auto module = std::dynamic_pointer_cast<dgmpp::Module>(self.item);
	module->setPreferredState(static_cast<dgmpp::Module::State>(preferredState));
}

- (BOOL) canHaveState:(NCFittingModuleState)state {
	auto module = std::dynamic_pointer_cast<dgmpp::Module>(self.item);
	return module->canHaveState(static_cast<dgmpp::Module::State>(state));
}

- (nullable NCFittingCharge*) charge {
	auto module = std::dynamic_pointer_cast<dgmpp::Module>(self.item);
	return module->getCharge() ? [[NCFittingCharge alloc] initWithItem:module->getCharge()] : nil;
}

- (void) setCharge:(NCFittingCharge *)charge {
	auto module = std::dynamic_pointer_cast<dgmpp::Module>(self.item);
	charge.item = module->setCharge(static_cast<dgmpp::TypeID>(charge.typeID));
}

- (NSIndexSet*) chargeGroups {
	auto module = std::dynamic_pointer_cast<dgmpp::Module>(self.item);
	NSMutableIndexSet* set = [NSMutableIndexSet new];
	for (auto groupID: module->getChargeGroups()) {
		[set addIndex:groupID];
	}
	return set;
}

- (NSInteger) chargeSize {
	auto module = std::dynamic_pointer_cast<dgmpp::Module>(self.item);
	return module->getChargeSize();
}

- (BOOL) requireTarget {
	auto module = std::dynamic_pointer_cast<dgmpp::Module>(self.item);
	return module->requireTarget();
}

- (NCFittingShip*) target {
	auto module = std::dynamic_pointer_cast<dgmpp::Module>(self.item);
	return module->getTarget() ? [[NCFittingShip alloc] initWithItem:module->getTarget()] : nil;
}

- (void) setTarget:(NCFittingShip *)target {
	auto module = std::dynamic_pointer_cast<dgmpp::Module>(self.item);
	if (target)
		module->clearTarget();
	else
		module->setTarget(std::dynamic_pointer_cast<dgmpp::Ship>(target.item));
}


- (double) reloadTime {
	auto module = std::dynamic_pointer_cast<dgmpp::Module>(self.item);
	return module->getReloadTime();
}

- (double) cycleTime {
	auto module = std::dynamic_pointer_cast<dgmpp::Module>(self.item);
	return module->getCycleTime();
}

- (double) rawCycleTime {
	auto module = std::dynamic_pointer_cast<dgmpp::Module>(self.item);
	return module->getRawCycleTime();
}

- (BOOL) factorReload {
	auto module = std::dynamic_pointer_cast<dgmpp::Module>(self.item);
	return module->factorReload();
}

- (void) setFactorReload:(BOOL)factorReload {
	auto module = std::dynamic_pointer_cast<dgmpp::Module>(self.item);
	return module->setFactorReload(factorReload);
}

- (NSInteger) charges {
	auto module = std::dynamic_pointer_cast<dgmpp::Module>(self.item);
	return module->getCharges();
}

- (NSInteger) shots {
	auto module = std::dynamic_pointer_cast<dgmpp::Module>(self.item);
	return module->getShots();
}

- (NSInteger) capUse {
	auto module = std::dynamic_pointer_cast<dgmpp::Module>(self.item);
	return module->getCapUse();
}

- (NCFittingDamage) dps {
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
	auto module = std::dynamic_pointer_cast<dgmpp::Module>(self.item);
	return module->getMaxRange();
}

- (double) falloff {
	auto module = std::dynamic_pointer_cast<dgmpp::Module>(self.item);
	return module->getFalloff();
}

- (double) accuracyScore {
	auto module = std::dynamic_pointer_cast<dgmpp::Module>(self.item);
	return module->getAccuracyScore();
}

- (double) signatureResolution {
	auto module = std::dynamic_pointer_cast<dgmpp::Module>(self.item);
	return module->getSignatureResolution();
}

- (double) lifeTime {
	auto module = std::dynamic_pointer_cast<dgmpp::Module>(self.item);
	return module->getLifeTime();
}

- (BOOL) isEnabled {
	auto module = std::dynamic_pointer_cast<dgmpp::Module>(self.item);
	return module->isEnabled();
}

- (double) angularVelocityWithTargetSignature:(double) targetSignature {
	auto module = std::dynamic_pointer_cast<dgmpp::Module>(self.item);
	return module->getAngularVelocity(targetSignature);
}

@end
