//
//  NCDBEufeItemGroup+CoreDataProperties.h
//  Neocom
//
//  Created by Артем Шиманский on 07.12.15.
//  Copyright © 2015 Artem Shimanski. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "NCDBEufeItemGroup.h"

NS_ASSUME_NONNULL_BEGIN

@interface NCDBEufeItemGroup (CoreDataProperties)

@property (nullable, nonatomic, retain) NSString *groupName;
@property (nullable, nonatomic, retain) NCDBEufeItemCategory *category;
@property (nullable, nonatomic, retain) NCDBEveIcon *icon;
@property (nullable, nonatomic, retain) NSSet<NCDBEufeItem *> *items;
@property (nullable, nonatomic, retain) NCDBEufeItemGroup *parentGroup;
@property (nullable, nonatomic, retain) NSSet<NCDBEufeItemGroup *> *subGroups;

@end

@interface NCDBEufeItemGroup (CoreDataGeneratedAccessors)

- (void)addItemsObject:(NCDBEufeItem *)value;
- (void)removeItemsObject:(NCDBEufeItem *)value;
- (void)addItems:(NSSet<NCDBEufeItem *> *)values;
- (void)removeItems:(NSSet<NCDBEufeItem *> *)values;

- (void)addSubGroupsObject:(NCDBEufeItemGroup *)value;
- (void)removeSubGroupsObject:(NCDBEufeItemGroup *)value;
- (void)addSubGroups:(NSSet<NCDBEufeItemGroup *> *)values;
- (void)removeSubGroups:(NSSet<NCDBEufeItemGroup *> *)values;

@end

NS_ASSUME_NONNULL_END
