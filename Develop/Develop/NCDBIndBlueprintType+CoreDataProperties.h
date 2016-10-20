//
//  NCDBIndBlueprintType+CoreDataProperties.h
//  Develop
//
//  Created by Artem Shimanski on 20.10.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCDBIndBlueprintType+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface NCDBIndBlueprintType (CoreDataProperties)

+ (NSFetchRequest<NCDBIndBlueprintType *> *)fetchRequest;

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
