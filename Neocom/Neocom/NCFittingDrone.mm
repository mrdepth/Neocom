//
//  NCFittingDrone.m
//  Neocom
//
//  Created by Artem Shimanski on 04.01.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

#import "NCFittingDrone.h"
#import "NCFittingProtected.h"
#import "NCFittingCharge.h"

@implementation NCFittingDrone

- (NCFittingFighterSquadron) squadron {
	auto drone = std::dynamic_pointer_cast<dgmpp::Drone>(self.item);
	return static_cast<NCFittingFighterSquadron>(drone->getSquadron());
}

- (NSInteger) squadronSize {
	auto drone = std::dynamic_pointer_cast<dgmpp::Drone>(self.item);
	return drone->getSquadronSize();
}

- (NCFittingShip*) target {
	auto drone = std::dynamic_pointer_cast<dgmpp::Drone>(self.item);
	return drone->getTarget() ? [[NCFittingShip alloc] initWithItem:drone->getTarget()] : nil;
}

- (void) setTarget:(NCFittingShip *)target {
	auto drone = std::dynamic_pointer_cast<dgmpp::Drone>(self.item);
	if (target)
		drone->clearTarget();
	else
		drone->setTarget(std::dynamic_pointer_cast<dgmpp::Ship>(target.item));
}

- (BOOL) dealsDamage {
	auto drone = std::dynamic_pointer_cast<dgmpp::Drone>(self.item);
	return drone->dealsDamage();
}

- (nullable NCFittingCharge*) charge {
	auto drone = std::dynamic_pointer_cast<dgmpp::Drone>(self.item);
	return drone->getCharge() ? [[NCFittingCharge alloc] initWithItem:drone->getCharge()] : nil;
}

- (BOOL) isActive {
	auto drone = std::dynamic_pointer_cast<dgmpp::Drone>(self.item);
	return drone->isActive();
}

- (double) cycleTime {
	auto drone = std::dynamic_pointer_cast<dgmpp::Drone>(self.item);
	return drone->getCycleTime();
}

- (NCFittingDamage) dps {
	auto drone = std::dynamic_pointer_cast<dgmpp::Drone>(self.item);
	auto damage = drone->getDps();
	NCFittingDamage result;
	
	result.em = damage.emAmount;
	result.thermal = damage.thermalAmount;
	result.kinetic = damage.kineticAmount;
	result.explosive = damage.explosiveAmount;
	
	return result;
}

- (NCFittingDamage) volley {
	auto drone = std::dynamic_pointer_cast<dgmpp::Drone>(self.item);
	auto damage = drone->getVolley();
	NCFittingDamage result;
	
	result.em = damage.emAmount;
	result.thermal = damage.thermalAmount;
	result.kinetic = damage.kineticAmount;
	result.explosive = damage.explosiveAmount;
	
	return result;
}

- (NCFittingDamage) dpsWithTarget:(NCFittingHostileTarget) target {
	auto drone = std::dynamic_pointer_cast<dgmpp::Drone>(self.item);
	dgmpp::HostileTarget hostileTarget(target.range, target.angularVelocity, target.signature, target.velocity);
	auto damage = drone->getDps(hostileTarget);
	NCFittingDamage result;
	
	result.em = damage.emAmount;
	result.thermal = damage.thermalAmount;
	result.kinetic = damage.kineticAmount;
	result.explosive = damage.explosiveAmount;
	
	return result;
}

- (double) maxRange {
	auto drone = std::dynamic_pointer_cast<dgmpp::Drone>(self.item);
	return drone->getMaxRange();
}

- (double) falloff {
	auto drone = std::dynamic_pointer_cast<dgmpp::Drone>(self.item);
	return drone->getFalloff();
}

- (double) accuracyScore {
	auto drone = std::dynamic_pointer_cast<dgmpp::Drone>(self.item);
	return drone->getAccuracyScore();
}

@end
