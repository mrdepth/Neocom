//
//  NCShoppingItem.h
//  Neocom
//
//  Created by Артем Шиманский on 27.03.15.
//  Copyright (c) 2015 Artem Shimanski. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class NCShoppingList;

@interface NCShoppingItem : NSManagedObject

@property (nonatomic) int32_t quantity;
@property (nonatomic) int32_t typeID;
@property (nonatomic, retain) NCShoppingList *shoppingList;

@end
