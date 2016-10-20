//
//  NCDBEveIcon+CoreDataProperties.h
//  Develop
//
//  Created by Artem Shimanski on 20.10.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCDBEveIcon+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface NCDBEveIcon (CoreDataProperties)

+ (NSFetchRequest<NCDBEveIcon *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSString *iconFile;
@property (nullable, nonatomic, retain) NSSet<NCDBRamActivity *> *activities;
@property (nullable, nonatomic, retain) NSSet<NCDBDgmAttributeType *> *attributeTypes;
@property (nullable, nonatomic, retain) NSSet<NCDBInvCategory *> *categories;
@property (nullable, nonatomic, retain) NSSet<NCDBInvGroup *> *groups;
@property (nullable, nonatomic, retain) NCDBEveIconImage *image;
@property (nullable, nonatomic, retain) NSSet<NCDBDgmppItemGroup *> *itemGroups;
@property (nullable, nonatomic, retain) NSSet<NCDBInvMarketGroup *> *marketGroups;
@property (nullable, nonatomic, retain) NSSet<NCDBCertMasteryLevel *> *masteryLevels;
@property (nullable, nonatomic, retain) NSSet<NCDBInvMetaGroup *> *metaGroups;
@property (nullable, nonatomic, retain) NSSet<NCDBNpcGroup *> *npcGroups;
@property (nullable, nonatomic, retain) NSSet<NCDBChrRace *> *races;
@property (nullable, nonatomic, retain) NSSet<NCDBInvType *> *types;

@end

@interface NCDBEveIcon (CoreDataGeneratedAccessors)

- (void)addActivitiesObject:(NCDBRamActivity *)value;
- (void)removeActivitiesObject:(NCDBRamActivity *)value;
- (void)addActivities:(NSSet<NCDBRamActivity *> *)values;
- (void)removeActivities:(NSSet<NCDBRamActivity *> *)values;

- (void)addAttributeTypesObject:(NCDBDgmAttributeType *)value;
- (void)removeAttributeTypesObject:(NCDBDgmAttributeType *)value;
- (void)addAttributeTypes:(NSSet<NCDBDgmAttributeType *> *)values;
- (void)removeAttributeTypes:(NSSet<NCDBDgmAttributeType *> *)values;

- (void)addCategoriesObject:(NCDBInvCategory *)value;
- (void)removeCategoriesObject:(NCDBInvCategory *)value;
- (void)addCategories:(NSSet<NCDBInvCategory *> *)values;
- (void)removeCategories:(NSSet<NCDBInvCategory *> *)values;

- (void)addGroupsObject:(NCDBInvGroup *)value;
- (void)removeGroupsObject:(NCDBInvGroup *)value;
- (void)addGroups:(NSSet<NCDBInvGroup *> *)values;
- (void)removeGroups:(NSSet<NCDBInvGroup *> *)values;

- (void)addItemGroupsObject:(NCDBDgmppItemGroup *)value;
- (void)removeItemGroupsObject:(NCDBDgmppItemGroup *)value;
- (void)addItemGroups:(NSSet<NCDBDgmppItemGroup *> *)values;
- (void)removeItemGroups:(NSSet<NCDBDgmppItemGroup *> *)values;

- (void)addMarketGroupsObject:(NCDBInvMarketGroup *)value;
- (void)removeMarketGroupsObject:(NCDBInvMarketGroup *)value;
- (void)addMarketGroups:(NSSet<NCDBInvMarketGroup *> *)values;
- (void)removeMarketGroups:(NSSet<NCDBInvMarketGroup *> *)values;

- (void)addMasteryLevelsObject:(NCDBCertMasteryLevel *)value;
- (void)removeMasteryLevelsObject:(NCDBCertMasteryLevel *)value;
- (void)addMasteryLevels:(NSSet<NCDBCertMasteryLevel *> *)values;
- (void)removeMasteryLevels:(NSSet<NCDBCertMasteryLevel *> *)values;

- (void)addMetaGroupsObject:(NCDBInvMetaGroup *)value;
- (void)removeMetaGroupsObject:(NCDBInvMetaGroup *)value;
- (void)addMetaGroups:(NSSet<NCDBInvMetaGroup *> *)values;
- (void)removeMetaGroups:(NSSet<NCDBInvMetaGroup *> *)values;

- (void)addNpcGroupsObject:(NCDBNpcGroup *)value;
- (void)removeNpcGroupsObject:(NCDBNpcGroup *)value;
- (void)addNpcGroups:(NSSet<NCDBNpcGroup *> *)values;
- (void)removeNpcGroups:(NSSet<NCDBNpcGroup *> *)values;

- (void)addRacesObject:(NCDBChrRace *)value;
- (void)removeRacesObject:(NCDBChrRace *)value;
- (void)addRaces:(NSSet<NCDBChrRace *> *)values;
- (void)removeRaces:(NSSet<NCDBChrRace *> *)values;

- (void)addTypesObject:(NCDBInvType *)value;
- (void)removeTypesObject:(NCDBInvType *)value;
- (void)addTypes:(NSSet<NCDBInvType *> *)values;
- (void)removeTypes:(NSSet<NCDBInvType *> *)values;

@end

NS_ASSUME_NONNULL_END
