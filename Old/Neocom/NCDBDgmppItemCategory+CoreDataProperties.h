//
//  NCDBDgmppItemCategory+CoreDataProperties.h
//  Neocom
//
//  Created by Артем Шиманский on 07.12.15.
//  Copyright © 2015 Artem Shimanski. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "NCDBDgmppItemCategory.h"

NS_ASSUME_NONNULL_BEGIN

@interface NCDBDgmppItemCategory (CoreDataProperties)

@property (nonatomic) int32_t category;
@property (nonatomic) int32_t subcategory;
@property (nullable, nonatomic, retain) NSSet<NCDBDgmppItem *> *dgmppItems;
@property (nullable, nonatomic, retain) NSSet<NCDBDgmppItemGroup *> *itemGroups;
@property (nullable, nonatomic, retain) NCDBChrRace *race;

@end

@interface NCDBDgmppItemCategory (CoreDataGeneratedAccessors)

- (void)addDgmppItemsObject:(NCDBDgmppItem *)value;
- (void)removeDgmppItemsObject:(NCDBDgmppItem *)value;
- (void)addDgmppItems:(NSSet<NCDBDgmppItem *> *)values;
- (void)removeDgmppItems:(NSSet<NCDBDgmppItem *> *)values;

- (void)addItemGroupsObject:(NCDBDgmppItemGroup *)value;
- (void)removeItemGroupsObject:(NCDBDgmppItemGroup *)value;
- (void)addItemGroups:(NSSet<NCDBDgmppItemGroup *> *)values;
- (void)removeItemGroups:(NSSet<NCDBDgmppItemGroup *> *)values;

@end

NS_ASSUME_NONNULL_END
