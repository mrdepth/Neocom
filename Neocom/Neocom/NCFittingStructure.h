//
//  NCFittingStructure.h
//  Neocom
//
//  Created by Artem Shimanski on 11.07.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

#import "NCFittingShip.h"

@interface NCFittingStructure : NCFittingShip
@property (readonly, nonnull) NSArray<NSNumber*>* supportedModuleCategories NS_REFINED_FOR_SWIFT;
@property (readonly, nonnull) NSArray<NSNumber*>* supportedDroneCategories NS_REFINED_FOR_SWIFT;
@property (readonly) NSInteger fuelBlockTypeID;
@property (readonly) double cycleFuelNeed;
@property (readonly) NSTimeInterval cycleTime;
@end
