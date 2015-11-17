//
//  NCShoppingList.h
//  Neocom
//
//  Created by Артем Шиманский on 01.04.15.
//  Copyright (c) 2015 Artem Shimanski. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "NCStorage.h"

#define NCSettingsCurrentShoppingListKey @"NCSettingsCurrentShoppingListKey"

@class NCShoppingItem;

@interface NCShoppingList : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSSet *shoppingGroups;

+ (void) setCurrentShoppingList:(NCShoppingList*) shoppingList;

@end

@interface NCShoppingList (CoreDataGeneratedAccessors)

- (void)addShoppingGroupsObject:(NSManagedObject *)value;
- (void)removeShoppingGroupsObject:(NSManagedObject *)value;
- (void)addShoppingGroups:(NSSet *)values;
- (void)removeShoppingGroups:(NSSet *)values;

@end
