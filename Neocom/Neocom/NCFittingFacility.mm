//
//  NCFittingFacility.m
//  Neocom
//
//  Created by Artem Shimanski on 22.06.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

#import "NCFittingFacility.h"
#import "NCFittingProtected.h"

@implementation NCFittingFacility {
	std::weak_ptr<dgmpp::Facility> _facility;
}

- (nonnull instancetype) initWithFacility:(std::shared_ptr<dgmpp::Facility> const&) facility engine:(nonnull NCFittingEngine*) engine {
	if (self = [self init]) {
		_facility = facility;
		_engine = engine;
	}
	return self;
}

- (nonnull instancetype) init {
	if (self = [super init]) {
	}
	return self;
}

+ (nullable instancetype) facility:(std::shared_ptr<dgmpp::Facility> const&) facility withEngine:(nonnull NCFittingEngine*) engine {
	if (!facility)
		return nil;
	if (std::dynamic_pointer_cast<dgmpp::Spaceport>(facility) != nullptr)
		return [[NCFittingSpaceport alloc] initWithFacility:facility engine:engine];
	else if (std::dynamic_pointer_cast<dgmpp::IndustryFacility>(facility) != nullptr)
		return [[NCFittingIndustryFacility alloc] initWithFacility:facility engine:engine];
	else if (std::dynamic_pointer_cast<dgmpp::ExtractorControlUnit>(facility) != nullptr)
		return [[NCFittingExtractorControlUnit alloc] initWithFacility:facility engine:engine];
	else if (std::dynamic_pointer_cast<dgmpp::StorageFacility>(facility) != nullptr)
		return [[NCFittingStorageFacility alloc] initWithFacility:facility engine:engine];
	else
		return [[NCFittingFacility alloc] initWithFacility:facility engine:engine];

}


- (std::shared_ptr<dgmpp::Facility>) facility {
	return _facility.lock();
}

- (void) setFacility:(std::shared_ptr<dgmpp::Facility>)facility {
	_facility = facility;
}

- (NSInteger) typeID {
	auto facility = self.facility;
	return facility ? static_cast<NSInteger>(facility->getTypeID()) : 0;
}

- (NSString*) typeName {
	auto facility = self.facility;
	return facility ? [NSString stringWithCString:facility->getTypeName().c_str() ?: "" encoding:NSUTF8StringEncoding] : @"";
}

- (NSInteger) groupID {
	auto facility = self.facility;
	return facility ? static_cast<NSInteger>(facility->getGroupID()) : 0;
}

- (int64_t) identifier {
	auto facility = self.facility;
	return facility ? facility->getIdentifier() : 0;
}

- (NSString*) facilityName {
	auto facility = self.facility;
	return facility ? [NSString stringWithCString:facility->getFacilityName().c_str() ?: "" encoding:NSUTF8StringEncoding] : @"";
}

- (NCFittingPlanet*) planet {
	auto facility = self.facility;
	return [[NCFittingPlanet alloc] initWithPlanet:facility->getOwner() engine:self.engine];
}

- (NSArray<NCFittingRoute*>*) inputs {
	NCVerifyFittingContext(self.engine);
	auto facility = self.facility;
	if (facility) {
		NSMutableArray* array = [NSMutableArray new];
		NCFittingEngine* engine = self.engine;
		for (auto i: facility->getInputs()) {
			[array addObject:[[NCFittingRoute alloc] initWithRoute:i engine:engine]];
		}
		return array;
	}
	else {
		return @[];
	}
}

- (NSArray<NCFittingRoute*>*) outputs {
	NCVerifyFittingContext(self.engine);
	auto facility = self.facility;
	if (facility) {
		NSMutableArray* array = [NSMutableArray new];
		NCFittingEngine* engine = self.engine;
		for (auto i: facility->getOutputs()) {
			[array addObject:[[NCFittingRoute alloc] initWithRoute:i engine:engine]];
		}
		return array;
	}
	else {
		return @[];
	}
}

- (double) capacity {
	NCVerifyFittingContext(self.engine);
	auto facility = self.facility;
	return facility ? facility->getCapacity() : 0;
}

- (NSArray<NCFittingState*>*) states {
	auto facility = self.facility;
	if (facility) {
		NSMutableArray* array = [NSMutableArray new];
		NCFittingEngine* engine = self.engine;
		for (auto i: facility->getStates()) {
			[array addObject:[NCFittingState state:i withEngine:engine]];
		}
		return array;
	}
	else {
		return @[];
	}
}

- (NSArray<NCFittingCommodity*>*) commodities {
	auto facility = self.facility;
	if (facility) {
		NSMutableArray* array = [NSMutableArray new];
		NCFittingEngine* engine = self.engine;
		for (auto i: facility->getCommodities()) {
			[array addObject:[[NCFittingCommodity alloc] initWithCommodity:i engine:engine]];
		}
		return array;
	}
	else {
		return @[];
	}
}

- (double) freeVolume {
	NCVerifyFittingContext(self.engine);
	auto facility = self.facility;
	return facility ? facility->getFreeVolume() : 0;
}


- (double) volume {
	NCVerifyFittingContext(self.engine);
	auto facility = self.facility;
	return facility ? facility->getVolume() : 0;
}

- (BOOL) isRouted {
	NCVerifyFittingContext(self.engine);
	auto facility = self.facility;
	return facility ? facility->routed() : 0;
}

- (void) addCommodityWithTypeID:(NSInteger) typeID quantity:(NSInteger) quantity {
	NCVerifyFittingContext(self.engine);
	auto facility = self.facility;
	if (facility) {
		facility->addCommodity(static_cast<dgmpp::TypeID>(typeID), static_cast<uint32_t>(quantity));
	}
}
- (nullable NCFittingCommodity*) commodityWithCommodity:(nonnull NCFittingCommodity*) commodity {
	NCVerifyFittingContext(self.engine);
	auto facility = self.facility;
	return facility ? [[NCFittingCommodity alloc] initWithCommodity:facility->getCommodity(*commodity.commodity) engine:self.engine] : nil;
}

- (nullable NCFittingCommodity*) incommingWithCommodity:(nonnull NCFittingCommodity*) commodity {
	NCVerifyFittingContext(self.engine);
	auto facility = self.facility;
	return facility ? [[NCFittingCommodity alloc] initWithCommodity:facility->getIncomming(*commodity.commodity) engine:self.engine] : nil;
}

- (NSInteger) freeStorageWithCommodity:(nonnull NCFittingCommodity*) commodity {
	NCVerifyFittingContext(self.engine);
	auto facility = self.facility;
	return facility ? facility->getFreeStorage(*commodity.commodity) : 0;
}


@end
