//
//  NCFittingStructure.m
//  Neocom
//
//  Created by Artem Shimanski on 11.07.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

#import "NCFittingStructure.h"
#import "NCFittingProtected.h"

@implementation NCFittingStructure

- (NSArray<NSNumber*>*) supportedModuleCategories {
	NCVerifyFittingContext(self.engine);
	auto structure = std::dynamic_pointer_cast<dgmpp::Structure>(self.item);
	
	if (structure) {
		NSMutableArray* array = [NSMutableArray new];
		for (const auto i: structure->getSupportedModuleCategories()) {
			[array addObject: @(static_cast<NSInteger>(i))];
		}
		return array;
	}
	else {
		return @[];
	}
}

- (NSArray<NSNumber*>*) supportedDroneCategories {
	NCVerifyFittingContext(self.engine);
	auto structure = std::dynamic_pointer_cast<dgmpp::Structure>(self.item);
	
	if (structure) {
		NSMutableArray* array = [NSMutableArray new];
		for (const auto i: structure->getSupportedDroneCategories()) {
			[array addObject: @(static_cast<NSInteger>(i))];
		}
		return array;
	}
	else {
		return @[];
	}
}

- (NSInteger) fuelBlockTypeID {
	NCVerifyFittingContext(self.engine);
	auto structure = std::dynamic_pointer_cast<dgmpp::Structure>(self.item);
	return structure ? static_cast<NSInteger>(structure->getFuelBlockTypeID()) : 0;

}

- (double) cycleFuelNeed {
	NCVerifyFittingContext(self.engine);
	auto structure = std::dynamic_pointer_cast<dgmpp::Structure>(self.item);
	return structure ? structure->getCycleFuelNeed() : 0;
}

- (NSTimeInterval) cycleTime {
	NCVerifyFittingContext(self.engine);
	auto structure = std::dynamic_pointer_cast<dgmpp::Structure>(self.item);
	return structure ? structure->getCycleTime() : 0;
}

@end
