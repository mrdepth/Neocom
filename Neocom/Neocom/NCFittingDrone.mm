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
	return drone ? static_cast<NCFittingFighterSquadron>(drone->getSquadron()) : NCFittingFighterSquadronNone;
}

- (NSInteger) squadronSize {
	NCVerifyFittingContext(self.engine);
	auto drone = std::dynamic_pointer_cast<dgmpp::Drone>(self.item);
	return drone ? drone->getSquadronSize() : 0;
}

- (NCFittingShip*) target {
	NCVerifyFittingContext(self.engine);
	auto drone = std::dynamic_pointer_cast<dgmpp::Drone>(self.item);
	return drone ? (drone->getTarget() ? (NCFittingShip*) [NCFittingItem item:drone->getTarget() withEngine:self.engine] : nil) : nil;
}

- (void) setTarget:(NCFittingShip *)target {
	NCVerifyFittingContext(self.engine);
	auto drone = std::dynamic_pointer_cast<dgmpp::Drone>(self.item);
	if (drone) {
		if (target)
			drone->clearTarget();
		else
			drone->setTarget(std::dynamic_pointer_cast<dgmpp::Ship>(target.item));
		[self.engine updateWithItem: self];
	}
}

- (BOOL) dealsDamage {
	NCVerifyFittingContext(self.engine);
	auto drone = std::dynamic_pointer_cast<dgmpp::Drone>(self.item);
	return drone ? drone->dealsDamage() : NO;
}

- (nullable NCFittingCharge*) charge {
	NCVerifyFittingContext(self.engine);
	auto drone = std::dynamic_pointer_cast<dgmpp::Drone>(self.item);
	return drone ? (drone->getCharge() ? (NCFittingCharge*) [NCFittingItem item:drone->getCharge() withEngine:self.engine] : nil) : nil;
}

- (BOOL) isActive {
	NCVerifyFittingContext(self.engine);
	auto drone = std::dynamic_pointer_cast<dgmpp::Drone>(self.item);
	return drone ? drone->isActive() : NO;
}

- (void) setIsActive:(BOOL)isActive {
	NCVerifyFittingContext(self.engine);
	auto drone = std::dynamic_pointer_cast<dgmpp::Drone>(self.item);
	if (drone) {
		drone->setActive(isActive);
		[self.engine updateWithItem: self];
	}
}

- (NSInteger) squadronTag {
	NCVerifyFittingContext(self.engine);
	auto drone = std::dynamic_pointer_cast<dgmpp::Drone>(self.item);
	return drone ? drone->getSquadronTag() : 0;
}

- (void) setSquadronTag:(NSInteger)squadronTag {
	NCVerifyFittingContext(self.engine);
	auto drone = std::dynamic_pointer_cast<dgmpp::Drone>(self.item);
	if (drone) {
		drone->setSquadronTag(static_cast<int>(squadronTag));
		[self.engine updateWithItem: self];
	}
}

- (double) cycleTime {
	NCVerifyFittingContext(self.engine);
	auto drone = std::dynamic_pointer_cast<dgmpp::Drone>(self.item);
	return drone ? drone->getCycleTime() : 0;
}

- (NCFittingDamage) dps {
	NCVerifyFittingContext(self.engine);
	auto drone = std::dynamic_pointer_cast<dgmpp::Drone>(self.item);
	NCFittingDamage result;
	
	if (drone) {
		auto damage = drone->getDps();

		result.em = damage.emAmount;
		result.thermal = damage.thermalAmount;
		result.kinetic = damage.kineticAmount;
		result.explosive = damage.explosiveAmount;
	}
	
	return result;
}

- (NCFittingDamage) volley {
	NCVerifyFittingContext(self.engine);
	auto drone = std::dynamic_pointer_cast<dgmpp::Drone>(self.item);
	NCFittingDamage result;
	
	if (drone) {
		auto damage = drone->getVolley();
		
		result.em = damage.emAmount;
		result.thermal = damage.thermalAmount;
		result.kinetic = damage.kineticAmount;
		result.explosive = damage.explosiveAmount;
	}
	
	return result;
}

- (NCFittingDamage) dpsWithTarget:(NCFittingHostileTarget) target {
	NCVerifyFittingContext(self.engine);
	auto drone = std::dynamic_pointer_cast<dgmpp::Drone>(self.item);
	NCFittingDamage result;
	
	if (drone) {
		dgmpp::HostileTarget hostileTarget(target.range, target.angularVelocity, target.signature, target.velocity);
		auto damage = drone->getDps(hostileTarget);
		
		result.em = damage.emAmount;
		result.thermal = damage.thermalAmount;
		result.kinetic = damage.kineticAmount;
		result.explosive = damage.explosiveAmount;
	}
	
	return result;
}

- (double) maxRange {
	NCVerifyFittingContext(self.engine);
	auto drone = std::dynamic_pointer_cast<dgmpp::Drone>(self.item);
	return drone ? drone->getMaxRange() : 0;
}

- (double) falloff {
	NCVerifyFittingContext(self.engine);
	auto drone = std::dynamic_pointer_cast<dgmpp::Drone>(self.item);
	return drone ? drone->getFalloff() : 0;
}

- (double) accuracyScore {
	NCVerifyFittingContext(self.engine);
	auto drone = std::dynamic_pointer_cast<dgmpp::Drone>(self.item);
	return drone ? drone->getAccuracyScore() : 0;
}

- (double) velocity {
	NCVerifyFittingContext(self.engine);
	auto drone = std::dynamic_pointer_cast<dgmpp::Drone>(self.item);
	return drone ? drone->getVelocity() : 0;
}

- (double) miningYield {
	NCVerifyFittingContext(self.engine);
	auto drone = std::dynamic_pointer_cast<dgmpp::Drone>(self.item);
	return drone ? drone->getMiningYield() : 0;
}

@end
