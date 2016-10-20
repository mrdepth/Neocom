//
//  NCDBDgmppItemGroup+CoreDataProperties.h
//  Develop
//
//  Created by Artem Shimanski on 20.10.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCDBDgmppItemGroup+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface NCDBDgmppItemGroup (CoreDataProperties)

+ (NSFetchRequest<NCDBDgmppItemGroup *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSString *groupName;
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
