//
//  NCDBEveIcon+CoreDataProperties.h
//  NCDatabase
//
//  Created by Artem Shimanski on 29.11.15.
//
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "NCDBEveIcon.h"

NS_ASSUME_NONNULL_BEGIN

@interface NCDBEveIcon (CoreDataProperties)

@property (nullable, nonatomic, retain) NSString *iconFile;
@property (nullable, nonatomic, retain) NSSet<NCDBRamActivity *> *activities;
@property (nullable, nonatomic, retain) NSSet<NCDBDgmAttributeType *> *attributeTypes;
@property (nullable, nonatomic, retain) NSSet<NCDBInvCategory *> *categories;
@property (nullable, nonatomic, retain) NSSet<NCDBInvGroup *> *groups;
@property (nullable, nonatomic, retain) NCDBEveIconImage *image;
@property (nullable, nonatomic, retain) NSSet<NCDBEufeItemGroup *> *itemGroups;
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

- (void)addItemGroupsObject:(NCDBEufeItemGroup *)value;
- (void)removeItemGroupsObject:(NCDBEufeItemGroup *)value;
- (void)addItemGroups:(NSSet<NCDBEufeItemGroup *> *)values;
- (void)removeItemGroups:(NSSet<NCDBEufeItemGroup *> *)values;

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
