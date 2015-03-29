//
//  NCShoppingItem+Neocom.h
//  Neocom
//
//  Created by Artem Shimanski on 29.03.15.
//  Copyright (c) 2015 Artem Shimanski. All rights reserved.
//

#import "NCShoppingItem.h"

@class NCDBInvType;
@class EVECentralMarketStatType;
@interface NCShoppingItem (Neocom)
@property (nonatomic, strong) NCDBInvType* type;
@property (nonatomic, strong) EVECentralMarketStatType* price;

+ (instancetype) shoppingItemWithType:(NCDBInvType*) type quantity:(int32_t) quantity;

@end
