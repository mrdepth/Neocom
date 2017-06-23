//
//  NCFittingCycle.m
//  Neocom
//
//  Created by Artem Shimanski on 22.06.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

#import "NCFittingCycle.h"
#import "NCFittingProtected.h"

@implementation NCFittingCycle {
	std::weak_ptr<dgmpp::Cycle> _cycle;
}

- (nonnull instancetype) initWithCycle:(std::shared_ptr<dgmpp::Cycle> const&) cycle engine:(nonnull NCFittingEngine*) engine {
	if (self = [self init]) {
		_cycle = cycle;
		_engine = engine;
	}
	return self;
}

- (nonnull instancetype) init {
	if (self = [super init]) {
	}
	return self;
}

+ (nullable instancetype) cycle:(const std::shared_ptr<dgmpp::Cycle> &)cycle withEngine:(NCFittingEngine *)engine {
	if (!cycle)
		return nil;
	if (std::dynamic_pointer_cast<dgmpp::ProductionCycle>(cycle) != nullptr)
		return [[NCFittingProductionCycle alloc] initWithCycle:cycle engine:engine];
	else
		return [[NCFittingCycle alloc] initWithCycle:cycle engine:engine];
	
}


- (std::shared_ptr<dgmpp::Cycle>) cycle {
	return _cycle.lock();
}

- (void) setCycle:(std::shared_ptr<dgmpp::Cycle>)cycle {
	_cycle = cycle;
}

- (NSTimeInterval) launchTime {
	NCVerifyFittingContext(self.engine);
	auto cycle = self.cycle;
	return cycle ? cycle->getLaunchTime() : 0;
}

- (NSTimeInterval) cycleTime {
	NCVerifyFittingContext(self.engine);
	auto cycle = self.cycle;
	return cycle ? cycle->getCycleTime() : 0;
}


@end
