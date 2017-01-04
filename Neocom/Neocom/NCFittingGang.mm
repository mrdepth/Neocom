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
	auto gang = std::dynamic_pointer_cast<dgmpp::Gang>(_item);
	auto pilot = gang->addPilot();
	return [[NCFittingCharacter alloc] initWithItem: pilot];
}

- (void) removePilot:(nonnull NCFittingCharacter*) character {
	auto gang = std::dynamic_pointer_cast<dgmpp::Gang>(_item);
	auto pilot = std::dynamic_pointer_cast<dgmpp::Character>(character->_item);
	gang->removePilot(pilot);
}

- (nonnull NSArray<NCFittingCharacter*>*) pilots {
	NSMutableArray* array = [NSMutableArray new];
	auto gang = std::dynamic_pointer_cast<dgmpp::Gang>(_item);
	for (auto pilot: gang->getPilots()) {
		[array addObject:[[NCFittingCharacter alloc] initWithItem: pilot]];
	}
	return array;
}

- (nullable NCFittingCharacter*) fleetBooster {
	auto gang = std::dynamic_pointer_cast<dgmpp::Gang>(_item);
	return gang->getFleetBooster() ? [[NCFittingCharacter alloc] initWithItem: gang->getFleetBooster()] : nil;
}

- (void) setFleetBooster:(nullable NCFittingCharacter*) fleetBooster {
	auto gang = std::dynamic_pointer_cast<dgmpp::Gang>(_item);
	if (fleetBooster)
		gang->setFleetBooster(std::dynamic_pointer_cast<dgmpp::Character>(fleetBooster->_item));
	else
		gang->removeFleetBooster();
}

@end
