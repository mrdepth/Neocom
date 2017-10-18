//
//  NCFittingIndustryFacility.m
//  Neocom
//
//  Created by Artem Shimanski on 22.06.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

#import "NCFittingIndustryFacility.h"
#import "NCFittingProtected.h"

@implementation NCFittingIndustryFacility

- (NCFittingSchematic*) schematic {
	NCVerifyFittingContext(self.engine);
	auto facility = std::dynamic_pointer_cast<dgmpp::IndustryFacility>(self.facility);
	return facility ? [[NCFittingSchematic alloc] initWithSchematic:facility->getSchematic() engine:self.engine] : nil;

}

- (void) setSchematic:(NCFittingSchematic *)schematic {
	NCVerifyFittingContext(self.engine);
	auto facility = std::dynamic_pointer_cast<dgmpp::IndustryFacility>(self.facility);
	if (facility) {
		schematic.schematic = facility->setSchematic(static_cast<dgmpp::TypeID>(schematic.schematicID));
		schematic.engine = self.engine;
	}
}

- (NSTimeInterval) launchTime {
	NCVerifyFittingContext(self.engine);
	auto facility = std::dynamic_pointer_cast<dgmpp::IndustryFacility>(self.facility);
	return facility ? facility->getLaunchTime() : 0;
}

- (void) setLaunchTime:(NSTimeInterval)launchTime {
	NCVerifyFittingContext(self.engine);
	auto facility = std::dynamic_pointer_cast<dgmpp::IndustryFacility>(self.facility);
	if (facility)
		facility->setLaunchTime(launchTime);
}

- (NSTimeInterval) cycleTime {
	NCVerifyFittingContext(self.engine);
	auto facility = std::dynamic_pointer_cast<dgmpp::IndustryFacility>(self.facility);
	return facility ? facility->getCycleTime() : 0;
}

- (NSInteger) quantityPerCycle {
	NCVerifyFittingContext(self.engine);
	auto facility = std::dynamic_pointer_cast<dgmpp::IndustryFacility>(self.facility);
	return facility ? facility->getQuantityPerCycle() : 0;
}

- (NCFittingCommodity*) output {
	NCVerifyFittingContext(self.engine);
	auto facility = std::dynamic_pointer_cast<dgmpp::IndustryFacility>(self.facility);
	return facility ? [[NCFittingCommodity alloc] initWithCommodity:facility->getOutput() engine:self.engine] : nil;
}


@end
