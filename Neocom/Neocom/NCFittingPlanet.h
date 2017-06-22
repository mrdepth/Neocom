//
//  NCFittingPlanet.h
//  Neocom
//
//  Created by Artem Shimanski on 22.06.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

#import <Foundation/Foundation.h>

@class NCFittingFacility;
@class NCFittingRoute;
@class NCFittingCommodity;
@class NCFittingEngine;

@interface NCFittingPlanet : NSObject

@property (readonly, nonnull) NSArray<NCFittingFacility*>* facilities;
@property (assign) NSTimeInterval lastUpdate;
@property (nonatomic, weak, nullable) NCFittingEngine* engine;

- (nullable NCFittingFacility*) addFacilityWithTypeID:(NSInteger) typeID identifier:(int64_t) identifier;
- (nullable NCFittingFacility*) addFacilityWithTypeID:(NSInteger) typeID;
- (void) removeFacility:(nonnull NCFittingFacility*) facility;
- (nullable NCFittingFacility*) facilityWithIdentifier:(int64_t) identifier;
- (nonnull NCFittingRoute*) addRouteFrom:(nonnull NCFittingFacility*) source to:(nonnull NCFittingFacility*) destination commodity:(nonnull NCFittingCommodity*) commodity identifier:(int64_t) identifier;
- (nonnull NCFittingRoute*) addRouteFrom:(nonnull NCFittingFacility*) source to:(nonnull NCFittingFacility*) destination commodity:(nonnull NCFittingCommodity*) commodity;
- (void) removeRoute:(nonnull NCFittingRoute*) route;
- (void) simulate;

- (nonnull instancetype) init NS_SWIFT_UNAVAILABLE("");

@end
