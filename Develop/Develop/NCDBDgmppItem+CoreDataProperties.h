//
//  NCDBDgmppItem+CoreDataProperties.h
//  Develop
//
//  Created by Artem Shimanski on 20.10.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCDBDgmppItem+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface NCDBDgmppItem (CoreDataProperties)

+ (NSFetchRequest<NCDBDgmppItem *> *)fetchRequest;

@property (nullable, nonatomic, retain) NCDBDgmppItemCategory *charge;
@property (nullable, nonatomic, retain) NCDBDgmppItemDamage *damage;
@property (nullable, nonatomic, retain) NSSet<NCDBDgmppItemGroup *> *groups;
@property (nullable, nonatomic, retain) NCDBDgmppItemRequirements *requirements;
@property (nullable, nonatomic, retain) NCDBDgmppItemShipResources *shipResources;
@property (nullable, nonatomic, retain) NCDBDgmppItemSpaceStructureResources *spaceStructureResources;
@property (nullable, nonatomic, retain) NCDBInvType *type;

@end

@interface NCDBDgmppItem (CoreDataGeneratedAccessors)

- (void)addGroupsObject:(NCDBDgmppItemGroup *)value;
- (void)removeGroupsObject:(NCDBDgmppItemGroup *)value;
- (void)addGroups:(NSSet<NCDBDgmppItemGroup *> *)values;
- (void)removeGroups:(NSSet<NCDBDgmppItemGroup *> *)values;

@end

NS_ASSUME_NONNULL_END
