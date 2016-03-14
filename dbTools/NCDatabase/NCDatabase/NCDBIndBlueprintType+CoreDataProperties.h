//
//  NCDBIndBlueprintType+CoreDataProperties.h
//  NCDatabase
//
//  Created by Артем Шиманский on 14.03.16.
//
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "NCDBIndBlueprintType.h"

NS_ASSUME_NONNULL_BEGIN

@interface NCDBIndBlueprintType (CoreDataProperties)

@property (nonatomic) int32_t maxProductionLimit;
@property (nullable, nonatomic, retain) NSSet<NCDBIndActivity *> *activities;
@property (nullable, nonatomic, retain) NCDBInvType *type;

@end

@interface NCDBIndBlueprintType (CoreDataGeneratedAccessors)

- (void)addActivitiesObject:(NCDBIndActivity *)value;
- (void)removeActivitiesObject:(NCDBIndActivity *)value;
- (void)addActivities:(NSSet<NCDBIndActivity *> *)values;
- (void)removeActivities:(NSSet<NCDBIndActivity *> *)values;

@end

NS_ASSUME_NONNULL_END
