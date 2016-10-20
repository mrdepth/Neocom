//
//  NCDBRamActivity+CoreDataProperties.h
//  Develop
//
//  Created by Artem Shimanski on 20.10.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCDBRamActivity+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface NCDBRamActivity (CoreDataProperties)

+ (NSFetchRequest<NCDBRamActivity *> *)fetchRequest;

@property (nonatomic) int32_t activityID;
@property (nullable, nonatomic, copy) NSString *activityName;
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
