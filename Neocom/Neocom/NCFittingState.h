//
//  NCFittingState.h
//  Neocom
//
//  Created by Artem Shimanski on 22.06.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

#import <Foundation/Foundation.h>

@class NCFittingCommodity;

@interface NCFittingState : NSObject
@property (readonly) NSTimeInterval timestamp;
@property (readonly) double volume;
@property (readonly, nonnull) NSArray<NCFittingCommodity*>* commodities;

@end
