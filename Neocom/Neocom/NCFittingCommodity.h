//
//  NCFittingCommodity.h
//  Neocom
//
//  Created by Artem Shimanski on 22.06.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NCFittingTypes.h"

@interface NCFittingCommodity : NSObject
@property (readonly) NSInteger typeID;
@property (readonly, nonnull) NSString* typeName;
@property (readonly) NSInteger quantity;
@property (readonly) double itemVolume;
@property (readonly) double volume;
@property (readonly) NCFittingCommodityTier tier;


@end
