//
//  NCShoppingList+CoreDataProperties.h
//  Develop
//
//  Created by Artem Shimanski on 18.10.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCShoppingList+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface NCShoppingList (CoreDataProperties)

+ (NSFetchRequest<NCShoppingList *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSString *name;
@property (nullable, nonatomic, retain) NSSet<NCShoppingGroup *> *shoppingGroups;

@end

@interface NCShoppingList (CoreDataGeneratedAccessors)

- (void)addShoppingGroupsObject:(NCShoppingGroup *)value;
- (void)removeShoppingGroupsObject:(NCShoppingGroup *)value;
- (void)addShoppingGroups:(NSSet<NCShoppingGroup *> *)values;
- (void)removeShoppingGroups:(NSSet<NCShoppingGroup *> *)values;

@end

NS_ASSUME_NONNULL_END
