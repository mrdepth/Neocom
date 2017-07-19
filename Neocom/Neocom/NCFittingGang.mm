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

- (nullable NCFittingCharacter*) addPilot {
	NCVerifyFittingContext(self.engine);
	auto gang = std::dynamic_pointer_cast<dgmpp::Gang>(self.item);
	if (gang) {
		auto pilot = gang->addPilot();
		[self.engine updateWithItem: self];
		return (NCFittingCharacter*) [NCFittingItem item: pilot withEngine:self.engine];
	}
	else {
		return nil;
	}
}

- (void) removePilot:(nonnull NCFittingCharacter*) character {
	NCVerifyFittingContext(self.engine);
	auto gang = std::dynamic_pointer_cast<dgmpp::Gang>(self.item);
	if (gang) {
		auto pilot = std::dynamic_pointer_cast<dgmpp::Character>(character.item);
		[self.engine assignIdentifier:nil forItem:[NCFittingItem item: pilot withEngine:self.engine]];
		gang->removePilot(pilot);
		[self.engine updateWithItem: self];
	}
}

- (nonnull NSArray<NCFittingCharacter*>*) pilots {
	NCVerifyFittingContext(self.engine);
	NSMutableArray* array = [NSMutableArray new];
	auto gang = std::dynamic_pointer_cast<dgmpp::Gang>(self.item);
	if (gang) {
		for (auto pilot: gang->getPilots()) {
			[array addObject:(NCFittingCharacter*) [NCFittingItem item: pilot withEngine:self.engine]];
		}
		return array;
	}
	else {
		return @[];
	}
}

@end
