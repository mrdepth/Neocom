//
//  NCFittingProductionState.h
//  Neocom
//
//  Created by Artem Shimanski on 22.06.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

#import "NCFittingState.h"

@class NCFittingCycle;

@interface NCFittingProductionState : NCFittingState
@property (readonly, nullable) NCFittingCycle* currentCycle;
@property (readonly) double efficiency;

@end
