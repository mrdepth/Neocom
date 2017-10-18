//
//  NCFittingIndustryFacility.h
//  Neocom
//
//  Created by Artem Shimanski on 22.06.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

#import "NCFittingFacility.h"

@class NCFittingSchematic;

@interface NCFittingIndustryFacility : NCFittingFacility
@property (nullable) NCFittingSchematic* schematic;
@property (assign) NSTimeInterval launchTime;
@property (readonly) NSTimeInterval cycleTime;
@property (readonly) NSInteger quantityPerCycle;
@property (readonly, nonnull) NCFittingCommodity* output;


@end
