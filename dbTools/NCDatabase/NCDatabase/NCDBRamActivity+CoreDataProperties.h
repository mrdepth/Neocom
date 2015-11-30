//
//  NCDBRamActivity+CoreDataProperties.h
//  NCDatabase
//
//  Created by Artem Shimanski on 29.11.15.
//
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "NCDBRamActivity.h"

NS_ASSUME_NONNULL_BEGIN

@interface NCDBRamActivity (CoreDataProperties)

@property (nonatomic) int32_t activityID;
@property (nullable, nonatomic, retain) NSString *activityName;
@property (nonatomic) BOOL published;
@property (nullable, nonatomic, retain) NSSet<NCDBRamAssemblyLineType *> *assemblyLineTypes;
@property (nullable, nonatomic, retain) NCDBEveIcon *icon;
@property (nullable, nonatomic, retain) NSSet<NCDBIndActivity *> *indActivities;

@end

@interface NCDBRamActivity (CoreDataGeneratedAccessors)

- (void)addAssemblyLineTypesObject:(NCDBRamAssemblyLineType *)value;
- (void)removeAssemblyLineTypesObject:(NCDBRamAssemblyLineType *)value;
- (void)addAssemblyLineTypes:(NSSet<NCDBRamAssemblyLineType *> *)values;
- (void)removeAssemblyLineTypes:(NSSet<NCDBRamAssemblyLineType *> *)values;

- (void)addIndActivitiesObject:(NCDBIndActivity *)value;
- (void)removeIndActivitiesObject:(NCDBIndActivity *)value;
- (void)addIndActivities:(NSSet<NCDBIndActivity *> *)values;
- (void)removeIndActivities:(NSSet<NCDBIndActivity *> *)values;

@end

NS_ASSUME_NONNULL_END
