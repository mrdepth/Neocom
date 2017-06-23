//
//  NCFittingExtractorControlUnit.m
//  Neocom
//
//  Created by Artem Shimanski on 22.06.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

#import "NCFittingExtractorControlUnit.h"
#import "NCFittingProtected.h"

@implementation NCFittingExtractorControlUnit

- (NSTimeInterval) launchTime {
	NCVerifyFittingContext(self.engine);
	auto facility = std::dynamic_pointer_cast<dgmpp::ExtractorControlUnit>(self.facility);
	return facility ? facility->getLaunchTime() : 0;
}

- (void) setLaunchTime:(NSTimeInterval)launchTime {
	NCVerifyFittingContext(self.engine);
	auto facility = std::dynamic_pointer_cast<dgmpp::ExtractorControlUnit>(self.facility);
	if (facility)
		facility->setLaunchTime(launchTime);
}

- (NSTimeInterval) installTime {
	NCVerifyFittingContext(self.engine);
	auto facility = std::dynamic_pointer_cast<dgmpp::ExtractorControlUnit>(self.facility);
	return facility ? facility->getInstallTime() : 0;
}

- (void) setInstallTime:(NSTimeInterval)installTime {
	NCVerifyFittingContext(self.engine);
	auto facility = std::dynamic_pointer_cast<dgmpp::ExtractorControlUnit>(self.facility);
	if (facility)
		facility->setInstallTime(installTime);
}

- (NSTimeInterval) expiryTime {
	NCVerifyFittingContext(self.engine);
	auto facility = std::dynamic_pointer_cast<dgmpp::ExtractorControlUnit>(self.facility);
	return facility ? facility->getExpiryTime() : 0;
}

- (void) setExpiryTime:(NSTimeInterval)expiryTime {
	NCVerifyFittingContext(self.engine);
	auto facility = std::dynamic_pointer_cast<dgmpp::ExtractorControlUnit>(self.facility);
	if (facility)
		facility->setExpiryTime(expiryTime);
}

- (NSTimeInterval) cycleTime {
	NCVerifyFittingContext(self.engine);
	auto facility = std::dynamic_pointer_cast<dgmpp::ExtractorControlUnit>(self.facility);
	return facility ? facility->getCycleTime() : 0;
}

- (void) setCycleTime:(NSTimeInterval)cycleTime {
	NCVerifyFittingContext(self.engine);
	auto facility = std::dynamic_pointer_cast<dgmpp::ExtractorControlUnit>(self.facility);
	if (facility)
		facility->setCycleTime(cycleTime);
}

- (NSInteger) quantityPerCycle {
	NCVerifyFittingContext(self.engine);
	auto facility = std::dynamic_pointer_cast<dgmpp::ExtractorControlUnit>(self.facility);
	return facility ? facility->getQuantityPerCycle() : 0;
}

- (void) setQuantityPerCycle:(NSInteger)quantityPerCycle {
	NCVerifyFittingContext(self.engine);
	auto facility = std::dynamic_pointer_cast<dgmpp::ExtractorControlUnit>(self.facility);
	if (facility)
		facility->setQuantityPerCycle(static_cast<uint32_t>(quantityPerCycle));
}

- (NCFittingCommodity*) output {
	NCVerifyFittingContext(self.engine);
	auto facility = std::dynamic_pointer_cast<dgmpp::ExtractorControlUnit>(self.facility);
	return facility ? [[NCFittingCommodity alloc] initWithCommodity:facility->getOutput() engine:self.engine] : nil;
}

- (NSInteger) yieldAtTime:(NSTimeInterval) time {
	NCVerifyFittingContext(self.engine);
	auto facility = std::dynamic_pointer_cast<dgmpp::ExtractorControlUnit>(self.facility);
	return facility ? facility->getYieldAtTime(time) : 0;
}



@end
