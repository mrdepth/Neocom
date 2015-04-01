//
//  NCShoppingGroup.h
//  Neocom
//
//  Created by Артем Шиманский on 01.04.15.
//  Copyright (c) 2015 Artem Shimanski. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class NCShoppingItem, NCShoppingList;

@interface NCShoppingGroup : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic) int32_t quantity;
@property (nonatomic, retain) NSString* identifier;
@property (nonatomic, retain) NSSet *shoppingItems;
@property (nonatomic, retain) NCShoppingList *shoppingList;
@property (nonatomic, retain) NSString* iconFile;
@end

@interface NCShoppingGroup (CoreDataGeneratedAccessors)

- (void)addShoppingItemsObject:(NCShoppingItem *)value;
- (void)removeShoppingItemsObject:(NCShoppingItem *)value;
- (void)addShoppingItems:(NSSet *)values;
- (void)removeShoppingItems:(NSSet *)values;

@end
