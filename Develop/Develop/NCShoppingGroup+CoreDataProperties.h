//
//  NCShoppingGroup+CoreDataProperties.h
//  Develop
//
//  Created by Artem Shimanski on 18.10.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCShoppingGroup+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface NCShoppingGroup (CoreDataProperties)

+ (NSFetchRequest<NCShoppingGroup *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSString *iconFile;
@property (nullable, nonatomic, copy) NSString *identifier;
@property (nonatomic) BOOL immutable;
@property (nullable, nonatomic, copy) NSString *name;
@property (nonatomic) int32_t quantity;
@property (nullable, nonatomic, retain) NSSet<NCShoppingItem *> *shoppingItems;
@property (nullable, nonatomic, retain) NCShoppingList *shoppingList;

@end

@interface NCShoppingGroup (CoreDataGeneratedAccessors)

- (void)addShoppingItemsObject:(NCShoppingItem *)value;
- (void)removeShoppingItemsObject:(NCShoppingItem *)value;
- (void)addShoppingItems:(NSSet<NCShoppingItem *> *)values;
- (void)removeShoppingItems:(NSSet<NCShoppingItem *> *)values;

@end

NS_ASSUME_NONNULL_END
