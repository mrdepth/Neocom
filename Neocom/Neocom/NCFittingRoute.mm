//
//  NCFittingRoute.m
//  Neocom
//
//  Created by Artem Shimanski on 22.06.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

#import "NCFittingRoute.h"
#import "NCFittingProtected.h"

@implementation NCFittingRoute {
	std::weak_ptr<const dgmpp::Route> _route;
}

- (nonnull instancetype) initWithRoute:(std::shared_ptr<const dgmpp::Route> const&) route engine:(nonnull NCFittingEngine*) engine {
	if (self = [self init]) {
		_route = route;
		_engine = engine;
	}
	return self;
}

- (nonnull instancetype) init {
	if (self = [super init]) {
	}
	return self;
}


- (std::shared_ptr<const dgmpp::Route>) route {
	return _route.lock();
}

- (void) setRoute:(std::shared_ptr<const dgmpp::Route>) route {
	_route = route;
}

- (NCFittingFacility*) source {
	NCVerifyFittingContext(self.engine);
	auto route = self.route;
	return route ? [NCFittingFacility facility:route->getSource() withEngine:self.engine] : nil;
}

- (NCFittingFacility*) destination {
	NCVerifyFittingContext(self.engine);
	auto route = self.route;
	return route ? [NCFittingFacility facility:route->getDestination() withEngine:self.engine] : nil;
}

- (NCFittingCommodity*) commodity {
	NCVerifyFittingContext(self.engine);
	auto route = self.route;
	return route ? [[NCFittingCommodity alloc] initWithCommodity:route->getCommodity() engine:self.engine] : nil;
}

@end
