//
//  NCDBDgmppItem+CoreDataProperties.h
//  Neocom
//
//  Created by Артем Шиманский on 07.12.15.
//  Copyright © 2015 Artem Shimanski. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "NCDBDgmppItem.h"

NS_ASSUME_NONNULL_BEGIN

@interface NCDBDgmppItem (CoreDataProperties)

@property (nullable, nonatomic, retain) NCDBDgmppItemCategory *charge;
@property (nullable, nonatomic, retain) NCDBDgmppItemDamage *damage;
@property (nullable, nonatomic, retain) NSSet<NCDBDgmppItemGroup *> *groups;
@property (nullable, nonatomic, retain) NCDBDgmppItemRequirements *requirements;
@property (nullable, nonatomic, retain) NCDBDgmppItemShipResources *shipResources;
@property (nullable, nonatomic, retain) NCDBInvType *type;

@end

@interface NCDBDgmppItem (CoreDataGeneratedAccessors)

- (void)addGroupsObject:(NCDBDgmppItemGroup *)value;
- (void)removeGroupsObject:(NCDBDgmppItemGroup *)value;
- (void)addGroups:(NSSet<NCDBDgmppItemGroup *> *)values;
- (void)removeGroups:(NSSet<NCDBDgmppItemGroup *> *)values;

@end

NS_ASSUME_NONNULL_END
