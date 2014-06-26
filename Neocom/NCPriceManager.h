//
//  NCPriceManager.h
//  Neocom
//
//  Created by Артем Шиманский on 03.03.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EVECentralAPI.h"

@interface NCPriceManager : NSObject
- (EVECentralMarketStatType*) priceWithType:(NSInteger) typeID;
- (NSDictionary*) pricesWithTypes:(NSArray*) types;
@end
