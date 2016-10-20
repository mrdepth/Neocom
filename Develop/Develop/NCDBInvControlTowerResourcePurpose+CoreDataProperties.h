//
//  NCDBInvControlTowerResourcePurpose+CoreDataProperties.h
//  Develop
//
//  Created by Artem Shimanski on 20.10.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCDBInvControlTowerResourcePurpose+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface NCDBInvControlTowerResourcePurpose (CoreDataProperties)

+ (NSFetchRequest<NCDBInvControlTowerResourcePurpose *> *)fetchRequest;

@property (nonatomic) int32_t purposeID;
@property (nullable, nonatomic, copy) NSString *purposeText;
@property (nullable, nonatomic, retain) NSSet<NCDBInvControlTowerResource *> *controlTowerResources;

@end

@interface NCDBInvControlTowerResourcePurpose (CoreDataGeneratedAccessors)

- (void)addControlTowerResourcesObject:(NCDBInvControlTowerResource *)value;
- (void)removeControlTowerResourcesObject:(NCDBInvControlTowerResource *)value;
- (void)addControlTowerResources:(NSSet<NCDBInvControlTowerResource *> *)values;
- (void)removeControlTowerResources:(NSSet<NCDBInvControlTowerResource *> *)values;

@end

NS_ASSUME_NONNULL_END
