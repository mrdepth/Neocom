//
//  NCFittingState.h
//  Neocom
//
//  Created by Artem Shimanski on 22.06.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

#import <Foundation/Foundation.h>

@class NCFittingCommodity;
@class NCFittingEngine;

@interface NCFittingState : NSObject
@property (readonly) NSTimeInterval timestamp;
@property (readonly) double volume;
@property (readonly, nonnull) NSArray<NCFittingCommodity*>* commodities;
@property (nonatomic, weak, nullable) NCFittingEngine* engine;

- (nonnull instancetype) init NS_SWIFT_UNAVAILABLE("");

@end
