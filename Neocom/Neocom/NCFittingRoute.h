//
//  NCFittingRoute.h
//  Neocom
//
//  Created by Artem Shimanski on 22.06.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

#import <Foundation/Foundation.h>

@class NCFittingFacility;
@class NCFittingCommodity;
@class NCFittingEngine;

@interface NCFittingRoute : NSObject
@property (readonly, nullable) NCFittingFacility* source;
@property (readonly, nullable) NCFittingFacility* destination;
@property (readonly, nullable) NCFittingCommodity* commodity;
@property (nonatomic, weak, nullable) NCFittingEngine* engine;

- (nonnull instancetype) init NS_SWIFT_UNAVAILABLE("");

@end
