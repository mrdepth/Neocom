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

- (void) addCommodityWithTypeID:(NSInteger) typeID quantity:(NSInteger) quantity;
- (nonnull NCFittingCommodity*) commodityWithCommodity:(nonnull NCFittingCommodity*) commodity;
- (nonnull NCFittingCommodity*) incommingWithCommodity:(nonnull NCFittingCommodity*) commodity;
- (NSInteger) freeStorageWithCommodity:(nonnull NCFittingCommodity*) commodity;

@end
