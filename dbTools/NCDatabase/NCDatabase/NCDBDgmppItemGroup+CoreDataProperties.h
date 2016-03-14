//
//  NCDBDgmppItemGroup+CoreDataProperties.h
//  NCDatabase
//
//  Created by Артем Шиманский on 14.03.16.
//
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "NCDBDgmppItemGroup.h"

NS_ASSUME_NONNULL_BEGIN

@interface NCDBDgmppItemGroup (CoreDataProperties)

@property (nullable, nonatomic, retain) NSString *groupName;
@property (nullable, nonatomic, retain) NCDBDgmppItemCategory *category;
@property (nullable, nonatomic, retain) NCDBEveIcon *icon;
@property (nullable, nonatomic, retain) NSSet<NCDBDgmppItem *> *items;
@property (nullable, nonatomic, retain) NCDBDgmppItemGroup *parentGroup;
@property (nullable, nonatomic, retain) NSSet<NCDBDgmppItemGroup *> *subGroups;

@end

@interface NCDBDgmppItemGroup (CoreDataGeneratedAccessors)

- (void)addItemsObject:(NCDBDgmppItem *)value;
- (void)removeItemsObject:(NCDBDgmppItem *)value;
- (void)addItems:(NSSet<NCDBDgmppItem *> *)values;
- (void)removeItems:(NSSet<NCDBDgmppItem *> *)values;

- (void)addSubGroupsObject:(NCDBDgmppItemGroup *)value;
- (void)removeSubGroupsObject:(NCDBDgmppItemGroup *)value;
- (void)addSubGroups:(NSSet<NCDBDgmppItemGroup *> *)values;
- (void)removeSubGroups:(NSSet<NCDBDgmppItemGroup *> *)values;

@end

NS_ASSUME_NONNULL_END
