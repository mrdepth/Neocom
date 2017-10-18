//
//  NCFittingExtractorControlUnit.h
//  Neocom
//
//  Created by Artem Shimanski on 22.06.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

#import "NCFittingFacility.h"

@class NCFittingCommodity;

@interface NCFittingExtractorControlUnit : NCFittingFacility
@property (assign) NSTimeInterval launchTime;
@property (assign) NSTimeInterval installTime;
@property (assign) NSTimeInterval expiryTime;
@property (assign) NSTimeInterval cycleTime;
@property (assign) NSInteger quantityPerCycle;
@property (readonly, nonnull) NCFittingCommodity* output;

- (NSInteger) yieldAtTime:(NSTimeInterval) time;

@end
