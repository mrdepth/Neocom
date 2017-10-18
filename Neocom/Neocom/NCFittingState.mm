//
//  NCFittingState.m
//  Neocom
//
//  Created by Artem Shimanski on 22.06.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

#import "NCFittingState.h"
#import "NCFittingProtected.h"

@implementation NCFittingState {
	std::weak_ptr<dgmpp::State> _state;
}

- (nonnull instancetype) initWithState:(std::shared_ptr<dgmpp::State> const&) state engine:(nonnull NCFittingEngine*) engine {
	if (self = [self init]) {
		_state = state;
		_engine = engine;
	}
	return self;
}

- (nonnull instancetype) init {
	if (self = [super init]) {
	}
	return self;
}

+ (nullable instancetype) state:(const std::shared_ptr<dgmpp::State> &)state withEngine:(NCFittingEngine *)engine {
	if (!state)
		return nil;
	if (std::dynamic_pointer_cast<dgmpp::ProductionState>(state) != nullptr)
		return [[NCFittingProductionState alloc] initWithState:state engine:engine];
	else
		return [[NCFittingState alloc] initWithState:state engine:engine];
	
}


- (std::shared_ptr<dgmpp::State>) state {
	return _state.lock();
}

- (void) setState:(std::shared_ptr<dgmpp::State>)state {
	_state = state;
}

- (NSTimeInterval) timestamp {
	NCVerifyFittingContext(self.engine);
	auto state = self.state;
	return state ? state->getTimestamp() : 0;
}

- (double) volume {
	NCVerifyFittingContext(self.engine);
	auto state = self.state;
	return state ? state->getVolume() : 0;
}

- (NSArray<NCFittingCommodity*>*) commodities {
	NCVerifyFittingContext(self.engine);
	auto state = self.state;
	if (state) {
		NSMutableArray* array = [NSMutableArray new];
		NCFittingEngine* engine = self.engine;
		for (auto i: state->getCommodities()) {
			[array addObject:[[NCFittingCommodity alloc] initWithCommodity:i engine:engine]];
		}
		return array;
	}
	else {
		return @[];
	}
}

@end
