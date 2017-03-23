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
	NCVerifyFittingContext(self.engine);
	auto drone = std::dynamic_pointer_cast<dgmpp::Drone>(self.item);
	return static_cast<NCFittingFighterSquadron>(drone->getSquadron());
}

- (NSInteger) squadronSize {
	NCVerifyFittingContext(self.engine);
	auto drone = std::dynamic_pointer_cast<dgmpp::Drone>(self.item);
	return drone->getSquadronSize();
}

- (NCFittingShip*) target {
	NCVerifyFittingContext(self.engine);
	auto drone = std::dynamic_pointer_cast<dgmpp::Drone>(self.item);
	return drone->getTarget() ? (NCFittingShip*) [NCFittingItem item:drone->getTarget() withEngine:self.engine] : nil;
}

- (void) setTarget:(NCFittingShip *)target {
	NCVerifyFittingContext(self.engine);
	auto drone = std::dynamic_pointer_cast<dgmpp::Drone>(self.item);
	if (target)
		drone->clearTarget();
	else
		drone->setTarget(std::dynamic_pointer_cast<dgmpp::Ship>(target.item));
	[self.engine updateWithItem: self];
}

- (BOOL) dealsDamage {
	NCVerifyFittingContext(self.engine);
	auto drone = std::dynamic_pointer_cast<dgmpp::Drone>(self.item);
	return drone->dealsDamage();
}

- (nullable NCFittingCharge*) charge {
	NCVerifyFittingContext(self.engine);
	auto drone = std::dynamic_pointer_cast<dgmpp::Drone>(self.item);
	return drone->getCharge() ? (NCFittingCharge*) [NCFittingItem item:drone->getCharge() withEngine:self.engine] : nil;
}

- (BOOL) isActive {
	NCVerifyFittingContext(self.engine);
	auto drone = std::dynamic_pointer_cast<dgmpp::Drone>(self.item);
	return drone->isActive();
}

- (void) setIsActive:(BOOL)isActive {
	NCVerifyFittingContext(self.engine);
	auto drone = std::dynamic_pointer_cast<dgmpp::Drone>(self.item);
	drone->setActive(isActive);
	[self.engine updateWithItem: self];
}

- (NSInteger) squadronTag {
	NCVerifyFittingContext(self.engine);
	auto drone = std::dynamic_pointer_cast<dgmpp::Drone>(self.item);
	return drone->getSquadronTag();
}

- (void) setSquadronTag:(NSInteger)squadronTag {
	NCVerifyFittingContext(self.engine);
	auto drone = std::dynamic_pointer_cast<dgmpp::Drone>(self.item);
	drone->setSquadronTag(static_cast<int>(squadronTag));
	[self.engine updateWithItem: self];
}

- (double) cycleTime {
	NCVerifyFittingContext(self.engine);
	auto drone = std::dynamic_pointer_cast<dgmpp::Drone>(self.item);
	return drone->getCycleTime();
}

- (NCFittingDamage) dps {
	NCVerifyFittingContext(self.engine);
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
	NCVerifyFittingContext(self.engine);
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
	NCVerifyFittingContext(self.engine);
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
	NCVerifyFittingContext(self.engine);
	auto drone = std::dynamic_pointer_cast<dgmpp::Drone>(self.item);
	return drone->getMaxRange();
}

- (double) falloff {
	NCVerifyFittingContext(self.engine);
	auto drone = std::dynamic_pointer_cast<dgmpp::Drone>(self.item);
	return drone->getFalloff();
}

- (double) accuracyScore {
	NCVerifyFittingContext(self.engine);
	auto drone = std::dynamic_pointer_cast<dgmpp::Drone>(self.item);
	return drone->getAccuracyScore();
}

- (double) velocity {
	NCVerifyFittingContext(self.engine);
	auto drone = std::dynamic_pointer_cast<dgmpp::Drone>(self.item);
	return drone->getVelocity();
}

- (double) miningYield {
	NCVerifyFittingContext(self.engine);
	auto drone = std::dynamic_pointer_cast<dgmpp::Drone>(self.item);
	return drone->getMiningYield();
}

@end
