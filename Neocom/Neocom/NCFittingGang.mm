//
//  NCFittingGang.m
//  Neocom
//
//  Created by Artem Shimanski on 04.01.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

#import "NCFittingGang.h"
#import "NCFittingProtected.h"

@implementation NCFittingGang

- (nonnull NCFittingCharacter*) addPilot {
	auto gang = std::dynamic_pointer_cast<dgmpp::Gang>(self.item);
	auto pilot = gang->addPilot();
	return [[NCFittingCharacter alloc] initWithItem: pilot];
}

- (void) removePilot:(nonnull NCFittingCharacter*) character {
	auto gang = std::dynamic_pointer_cast<dgmpp::Gang>(self.item);
	auto pilot = std::dynamic_pointer_cast<dgmpp::Character>(character.item);
	gang->removePilot(pilot);
}

- (nonnull NSArray<NCFittingCharacter*>*) pilots {
	NSMutableArray* array = [NSMutableArray new];
	auto gang = std::dynamic_pointer_cast<dgmpp::Gang>(self.item);
	for (auto pilot: gang->getPilots()) {
		[array addObject:[[NCFittingCharacter alloc] initWithItem: pilot]];
	}
	return array;
}

- (nullable NCFittingCharacter*) fleetBooster {
	auto gang = std::dynamic_pointer_cast<dgmpp::Gang>(self.item);
	return gang->getFleetBooster() ? [[NCFittingCharacter alloc] initWithItem: gang->getFleetBooster()] : nil;
}

- (void) setFleetBooster:(nullable NCFittingCharacter*) fleetBooster {
	auto gang = std::dynamic_pointer_cast<dgmpp::Gang>(self.item);
	if (fleetBooster)
		gang->setFleetBooster(std::dynamic_pointer_cast<dgmpp::Character>(fleetBooster.item));
	else
		gang->removeFleetBooster();
}

- (nullable NCFittingCharacter*) wingBooster {
	auto gang = std::dynamic_pointer_cast<dgmpp::Gang>(self.item);
	return gang->getWingBooster() ? [[NCFittingCharacter alloc] initWithItem: gang->getWingBooster()] : nil;
}

- (void) setWingBooster:(NCFittingCharacter *) wingBooster {
	auto gang = std::dynamic_pointer_cast<dgmpp::Gang>(self.item);
	if (wingBooster)
		gang->setWingBooster(std::dynamic_pointer_cast<dgmpp::Character>(wingBooster.item));
	else
		gang->removeWingBooster();
}

- (nullable NCFittingCharacter*) squadBooster {
	auto gang = std::dynamic_pointer_cast<dgmpp::Gang>(self.item);
	return gang->getSquadBooster() ? [[NCFittingCharacter alloc] initWithItem: gang->getSquadBooster()] : nil;
}

- (void) setSquadBooster:(NCFittingCharacter *) squadBooster {
	auto gang = std::dynamic_pointer_cast<dgmpp::Gang>(self.item);
	if (squadBooster)
		gang->setSquadBooster(std::dynamic_pointer_cast<dgmpp::Character>(squadBooster.item));
	else
		gang->removeSquadBooster();
}


@end
