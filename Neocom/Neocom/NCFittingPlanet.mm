//
//  NCFittingPlanet.m
//  Neocom
//
//  Created by Artem Shimanski on 22.06.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

#import "NCFittingPlanet.h"
#import "NCFittingProtected.h"


@implementation NCFittingPlanet {
	std::weak_ptr<dgmpp::Planet> _planet;
	NSInteger _typeID;
}

- (nonnull instancetype) initWithPlanet:(std::shared_ptr<dgmpp::Planet> const&) planet engine:(nonnull NCFittingEngine*) engine {
	if (self = [self init]) {
		_planet = planet;
		_engine = engine;
	}
	return self;
}

- (nonnull instancetype) initWithTypeID:(NSInteger) typeID {
	if (self = [super init]) {
		_typeID = typeID;
	}
	return self;
}

- (nonnull instancetype) init {
	if (self = [super init]) {
	}
	return self;
}

- (std::shared_ptr<dgmpp::Planet>) planet {
	return _planet.lock();
}

- (void) setPlanet:(std::shared_ptr<dgmpp::Planet>)planet {
	_planet = planet;
}

- (NSInteger) typeID {
	auto planet = self.planet;
	return planet ? static_cast<NSInteger>(planet->getTypeID()) : _typeID;
}

- (nonnull NSArray<NCFittingFacility*>*) facilities {
	NCVerifyFittingContext(self.engine);
	auto planet = self.planet;
	if (planet) {
		NSMutableArray* array = [NSMutableArray new];
		NCFittingEngine* engine = self.engine;
		for (auto i: planet->getFacilities()) {
			[array addObject:[NCFittingFacility facility:i withEngine:engine]];
		}
		return array;
	}
	else {
		return @[];
	}
}

- (NSTimeInterval) lastUpdate {
	auto planet = self.planet;
	return planet ? planet->getLastUpdate() : 0;
}

- (void) setLastUpdate:(NSTimeInterval)lastUpdate {
	NCVerifyFittingContext(self.engine);
	auto planet = self.planet;
	if (planet) {
		planet->setLastUpdate(lastUpdate);
	}
}

- (nullable NCFittingFacility*) addFacilityWithTypeID:(NSInteger) typeID identifier:(int64_t) identifier {
	NCVerifyFittingContext(self.engine);
	auto planet = self.planet;
	if (planet) {
		try {
			return [NCFittingFacility facility: planet->addFacility(static_cast<dgmpp::TypeID>(typeID), identifier) withEngine:self.engine];
		}
		catch (...) {
			return nil;
		}
	}
	else {
		return nil;
	}
}

- (nullable NCFittingFacility*) addFacilityWithTypeID:(NSInteger) typeID {
	return [self addFacilityWithTypeID:typeID identifier:0];
}

- (void) removeFacility:(nonnull NCFittingFacility*) facility {
	NCVerifyFittingContext(self.engine);
	auto planet = self.planet;
	if (planet) {
		planet->removeFacility(facility.facility);
	}
}

- (nullable NCFittingFacility*) facilityWithIdentifier:(int64_t) identifier {
	NCVerifyFittingContext(self.engine);
	auto planet = self.planet;
	return planet ? [NCFittingFacility facility:planet->findFacility(identifier) withEngine:self.engine] : nil;
}

- (nullable NCFittingRoute*) addRouteFrom:(nonnull NCFittingFacility*) source to:(nonnull NCFittingFacility*) destination commodity:(nonnull NCFittingCommodity*) commodity identifier:(int64_t) identifier {
	NCVerifyFittingContext(self.engine);
	auto planet = self.planet;
	return planet ? [[NCFittingRoute alloc] initWithRoute:planet->addRoute(source.facility, destination.facility, *commodity.commodity, identifier) engine:self.engine] : nil;
}

- (nullable NCFittingRoute*) addRouteFrom:(nonnull NCFittingFacility*) source to:(nonnull NCFittingFacility*) destination commodity:(nonnull NCFittingCommodity*) commodity {
	NCVerifyFittingContext(self.engine);
	return [self addRouteFrom:source to:destination commodity:commodity identifier: 0];
}

- (void) removeRoute:(nonnull NCFittingRoute*) route {
	NCVerifyFittingContext(self.engine);
	auto planet = self.planet;
	if (planet) {
		planet->removeRoute(route.route);
	}
}

- (NSTimeInterval) simulate {
	NCVerifyFittingContext(self.engine);
	auto planet = self.planet;
	try {
		return planet ? planet->simulate() : 0;
	}
	catch(...) {
		return 0;
	}
}


@end
