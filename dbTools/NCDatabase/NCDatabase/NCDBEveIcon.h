//
//  NCDBEveIcon.h
//  NCDatabase
//
//  Created by Артем Шиманский on 13.06.14.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class NCDBCertMasteryLevel, NCDBChrRace, NCDBDgmAttributeType, NCDBEveIconImage, NCDBInvCategory, NCDBInvGroup, NCDBInvMarketGroup, NCDBInvMetaGroup, NCDBInvType, NCDBNpcGroup, NCDBRamActivity;

@interface NCDBEveIcon : NSManagedObject

@property (nonatomic, retain) NSString * iconFile;
@property (nonatomic, retain) NSSet *activities;
@property (nonatomic, retain) NSSet *attributeTypes;
@property (nonatomic, retain) NSSet *categories;
@property (nonatomic, retain) NSSet *groups;
@property (nonatomic, retain) NSSet *marketGroups;
@property (nonatomic, retain) NSSet *masteryLevelClaimedIcons;
@property (nonatomic, retain) NSSet *masteryLevelUnclaimedIcons;
@property (nonatomic, retain) NSSet *metaGroups;
@property (nonatomic, retain) NSSet *npcGroups;
@property (nonatomic, retain) NSSet *races;
@property (nonatomic, retain) NSSet *types;
@property (nonatomic, retain) NCDBEveIconImage *image;
@end

@interface NCDBEveIcon (CoreDataGeneratedAccessors)

- (void)addActivitiesObject:(NCDBRamActivity *)value;
- (void)removeActivitiesObject:(NCDBRamActivity *)value;
- (void)addActivities:(NSSet *)values;
- (void)removeActivities:(NSSet *)values;

- (void)addAttributeTypesObject:(NCDBDgmAttributeType *)value;
- (void)removeAttributeTypesObject:(NCDBDgmAttributeType *)value;
- (void)addAttributeTypes:(NSSet *)values;
- (void)removeAttributeTypes:(NSSet *)values;

- (void)addCategoriesObject:(NCDBInvCategory *)value;
- (void)removeCategoriesObject:(NCDBInvCategory *)value;
- (void)addCategories:(NSSet *)values;
- (void)removeCategories:(NSSet *)values;

- (void)addGroupsObject:(NCDBInvGroup *)value;
- (void)removeGroupsObject:(NCDBInvGroup *)value;
- (void)addGroups:(NSSet *)values;
- (void)removeGroups:(NSSet *)values;

- (void)addMarketGroupsObject:(NCDBInvMarketGroup *)value;
- (void)removeMarketGroupsObject:(NCDBInvMarketGroup *)value;
- (void)addMarketGroups:(NSSet *)values;
- (void)removeMarketGroups:(NSSet *)values;

- (void)addMasteryLevelClaimedIconsObject:(NCDBCertMasteryLevel *)value;
- (void)removeMasteryLevelClaimedIconsObject:(NCDBCertMasteryLevel *)value;
- (void)addMasteryLevelClaimedIcons:(NSSet *)values;
- (void)removeMasteryLevelClaimedIcons:(NSSet *)values;

- (void)addMasteryLevelUnclaimedIconsObject:(NCDBCertMasteryLevel *)value;
- (void)removeMasteryLevelUnclaimedIconsObject:(NCDBCertMasteryLevel *)value;
- (void)addMasteryLevelUnclaimedIcons:(NSSet *)values;
- (void)removeMasteryLevelUnclaimedIcons:(NSSet *)values;

- (void)addMetaGroupsObject:(NCDBInvMetaGroup *)value;
- (void)removeMetaGroupsObject:(NCDBInvMetaGroup *)value;
- (void)addMetaGroups:(NSSet *)values;
- (void)removeMetaGroups:(NSSet *)values;

- (void)addNpcGroupsObject:(NCDBNpcGroup *)value;
- (void)removeNpcGroupsObject:(NCDBNpcGroup *)value;
- (void)addNpcGroups:(NSSet *)values;
- (void)removeNpcGroups:(NSSet *)values;

- (void)addRacesObject:(NCDBChrRace *)value;
- (void)removeRacesObject:(NCDBChrRace *)value;
- (void)addRaces:(NSSet *)values;
- (void)removeRaces:(NSSet *)values;

- (void)addTypesObject:(NCDBInvType *)value;
- (void)removeTypesObject:(NCDBInvType *)value;
- (void)addTypes:(NSSet *)values;
- (void)removeTypes:(NSSet *)values;

@end
