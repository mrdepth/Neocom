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

@interface NCFittingRoute : NSObject
@property (readonly, nullable) NCFittingFacility* source;
@property (readonly, nullable) NCFittingFacility* destination;
@property (readonly, nonnull) NCFittingCommodity* commodity;

@end
