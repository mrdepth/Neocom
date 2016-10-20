//
//  NCDBInvControlTower+CoreDataProperties.h
//  Develop
//
//  Created by Artem Shimanski on 20.10.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCDBInvControlTower+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface NCDBInvControlTower (CoreDataProperties)

+ (NSFetchRequest<NCDBInvControlTower *> *)fetchRequest;

@property (nullable, nonatomic, retain) NSSet<NCDBInvControlTowerResource *> *resources;
@property (nullable, nonatomic, retain) NCDBInvType *type;

@end

@interface NCDBInvControlTower (CoreDataGeneratedAccessors)

- (void)addResourcesObject:(NCDBInvControlTowerResource *)value;
- (void)removeResourcesObject:(NCDBInvControlTowerResource *)value;
- (void)addResources:(NSSet<NCDBInvControlTowerResource *> *)values;
- (void)removeResources:(NSSet<NCDBInvControlTowerResource *> *)values;

@end

NS_ASSUME_NONNULL_END
