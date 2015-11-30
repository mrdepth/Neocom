//
//  NCDBEufeItemCategory+CoreDataProperties.h
//  Neocom
//
//  Created by Artem Shimanski on 29.11.15.
//  Copyright © 2015 Artem Shimanski. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "NCDBEufeItemCategory.h"

NS_ASSUME_NONNULL_BEGIN

@interface NCDBEufeItemCategory (CoreDataProperties)

@property (nonatomic) int32_t category;
@property (nonatomic) int32_t subcategory;
@property (nullable, nonatomic, retain) NSSet<NCDBEufeItem *> *eufeItems;
@property (nullable, nonatomic, retain) NSSet<NCDBEufeItemGroup *> *itemGroups;
@property (nullable, nonatomic, retain) NCDBChrRace *race;

@end

@interface NCDBEufeItemCategory (CoreDataGeneratedAccessors)

- (void)addEufeItemsObject:(NCDBEufeItem *)value;
- (void)removeEufeItemsObject:(NCDBEufeItem *)value;
- (void)addEufeItems:(NSSet<NCDBEufeItem *> *)values;
- (void)removeEufeItems:(NSSet<NCDBEufeItem *> *)values;

- (void)addItemGroupsObject:(NCDBEufeItemGroup *)value;
- (void)removeItemGroupsObject:(NCDBEufeItemGroup *)value;
- (void)addItemGroups:(NSSet<NCDBEufeItemGroup *> *)values;
- (void)removeItemGroups:(NSSet<NCDBEufeItemGroup *> *)values;

@end

NS_ASSUME_NONNULL_END
