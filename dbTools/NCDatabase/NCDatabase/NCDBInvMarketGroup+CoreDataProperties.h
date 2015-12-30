//
//  NCDBInvMarketGroup+CoreDataProperties.h
//  NCDatabase
//
//  Created by Артем Шиманский on 30.12.15.
//
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "NCDBInvMarketGroup.h"

NS_ASSUME_NONNULL_BEGIN

@interface NCDBInvMarketGroup (CoreDataProperties)

@property (nonatomic) int32_t marketGroupID;
@property (nullable, nonatomic, retain) NSString *marketGroupName;
@property (nullable, nonatomic, retain) NCDBEveIcon *icon;
@property (nullable, nonatomic, retain) NCDBInvMarketGroup *parentGroup;
@property (nullable, nonatomic, retain) NSSet<NCDBInvMarketGroup *> *subGroups;
@property (nullable, nonatomic, retain) NSSet<NCDBInvType *> *types;

@end

@interface NCDBInvMarketGroup (CoreDataGeneratedAccessors)

- (void)addSubGroupsObject:(NCDBInvMarketGroup *)value;
- (void)removeSubGroupsObject:(NCDBInvMarketGroup *)value;
- (void)addSubGroups:(NSSet<NCDBInvMarketGroup *> *)values;
- (void)removeSubGroups:(NSSet<NCDBInvMarketGroup *> *)values;

- (void)addTypesObject:(NCDBInvType *)value;
- (void)removeTypesObject:(NCDBInvType *)value;
- (void)addTypes:(NSSet<NCDBInvType *> *)values;
- (void)removeTypes:(NSSet<NCDBInvType *> *)values;

@end

NS_ASSUME_NONNULL_END
