//
//  NCShoppingList.h
//  Neocom
//
//  Created by Артем Шиманский on 27.03.15.
//  Copyright (c) 2015 Artem Shimanski. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "NCStorage.h"

@class NCShoppingItem;

@interface NCStorage(NCShoppingList)
- (NSArray*) allShoppingLists;
@end


@interface NCShoppingList : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSSet *items;

+ (instancetype) currentShoppingList;
+ (void) setCurrentShoppingList:(NCShoppingList*) shoppingList;

@end

@interface NCShoppingList (CoreDataGeneratedAccessors)

- (void)addItemsObject:(NCShoppingItem *)value;
- (void)removeItemsObject:(NCShoppingItem *)value;
- (void)addItems:(NSSet *)values;
- (void)removeItems:(NSSet *)values;

@end
