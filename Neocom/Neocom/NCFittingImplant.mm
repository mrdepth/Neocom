//
//  NCFittingImplant.m
//  Neocom
//
//  Created by Artem Shimanski on 04.01.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

#import "NCFittingImplant.h"
#import "NCFittingProtected.h"

@implementation NCFittingImplant

- (NSInteger) slot {
	auto implant = std::dynamic_pointer_cast<dgmpp::Implant>(self.item);
	return implant ? implant->getSlot() : 0;
}

@end
