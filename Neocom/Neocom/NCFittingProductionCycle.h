//
//  NCFittingProductionCycle.h
//  Neocom
//
//  Created by Artem Shimanski on 22.06.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

#import "NCFittingCycle.h"

@class NCFittingCommodity;

@interface NCFittingProductionCycle : NCFittingCycle;
@property (readonly, nonnull) NCFittingCommodity* yield;
@property (readonly, nonnull) NCFittingCommodity* waste;
@end
