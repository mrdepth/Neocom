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
@property (nonatomic, assign) double price;

- (id) initWithTypeID:(int32_t) typeID quantity:(int32_t) quantity entity:(NSEntityDescription*) entity insertIntoManagedObjectContext:(NSManagedObjectContext*) context;
@end
