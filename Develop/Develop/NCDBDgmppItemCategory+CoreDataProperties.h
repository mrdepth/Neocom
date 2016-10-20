//
//  NCDBDgmppItemCategory+CoreDataProperties.h
//  Develop
//
//  Created by Artem Shimanski on 20.10.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCDBDgmppItemCategory+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface NCDBDgmppItemCategory (CoreDataProperties)

+ (NSFetchRequest<NCDBDgmppItemCategory *> *)fetchRequest;

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
