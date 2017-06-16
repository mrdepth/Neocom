//
//  NCFittingBooster.m
//  Neocom
//
//  Created by Artem Shimanski on 04.01.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

#import "NCFittingBooster.h"
#import "NCFittingProtected.h"

@implementation NCFittingBooster

- (NSInteger) slot {
	auto booster = std::dynamic_pointer_cast<dgmpp::Booster>(self.item);
	return booster ? booster->getSlot() : 0;
}

@end
