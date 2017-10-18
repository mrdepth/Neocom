//
//  NCFittingFacility.h
//  Neocom
//
//  Created by Artem Shimanski on 22.06.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

#import <Foundation/Foundation.h>

@class NCFittingPlanet;
@class NCFittingRoute;
@class NCFittingState;
@class NCFittingCommodity;
@class NCFittingEngine;

@interface NCFittingFacility : NSObject
@property (readonly) NSInteger typeID;
@property (readonly, nonnull) NSString* typeName;
@property (readonly) NSInteger groupID;
@property (readonly) int64_t identifier;
@property (readonly, nonnull) NSString* facilityName;
@property (readonly, nullable) NCFittingPlanet* planet;
@property (readonly, nonnull) NSArray<NCFittingRoute*>* inputs;
@property (readonly, nonnull) NSArray<NCFittingRoute*>* outputs;
@property (readonly) double capacity;
@property (readonly, nonnull) NSArray<NCFittingState*>* states;
@property (readonly, nonnull) NSArray<NCFittingCommodity*>* commodities;
@property (readonly) double freeVolume;
@property (readonly) double volume;
@property (readonly) BOOL isRouted;
@property (nonatomic, weak, nullable) NCFittingEngine* engine;


- (void) addCommodityWithTypeID:(NSInteger) typeID quantity:(NSInteger) quantity NS_SWIFT_NAME(addCommodity(typeID:quantity:));
- (nullable NCFittingCommodity*) commodityWithCommodity:(nonnull NCFittingCommodity*) commodity;
- (nullable NCFittingCommodity*) incommingWithCommodity:(nonnull NCFittingCommodity*) commodity;
- (NSInteger) freeStorageWithCommodity:(nonnull NCFittingCommodity*) commodity;
- (nonnull instancetype) init NS_SWIFT_UNAVAILABLE("");

@end
