//
//  NCShoppingItem.h
//  Neocom
//
//  Created by Артем Шиманский on 01.04.15.
//  Copyright (c) 2015 Artem Shimanski. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class NCShoppingList, NCShoppingGroup;

@interface NCShoppingItem : NSManagedObject

@property (nonatomic, assign) int32_t finished;
@property (nonatomic, assign) int32_t quantity;
@property (nonatomic, assign) int32_t typeID;
@property (nonatomic, retain) NCShoppingGroup *shoppingGroup;

@end
