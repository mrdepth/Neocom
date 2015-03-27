//
//  NCShoppingList.h
//  Neocom
//
//  Created by Артем Шиманский on 27.03.15.
//  Copyright (c) 2015 Artem Shimanski. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class NCShoppingItem;

@interface NCShoppingList : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSSet *items;
@end

@interface NCShoppingList (CoreDataGeneratedAccessors)

- (void)addItemsObject:(NCShoppingItem *)value;
- (void)removeItemsObject:(NCShoppingItem *)value;
- (void)addItems:(NSSet *)values;
- (void)removeItems:(NSSet *)values;

@end
