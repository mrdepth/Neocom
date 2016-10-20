//
//  NCDBInvControlTowerResource+CoreDataProperties.h
//  Develop
//
//  Created by Artem Shimanski on 20.10.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCDBInvControlTowerResource+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface NCDBInvControlTowerResource (CoreDataProperties)

+ (NSFetchRequest<NCDBInvControlTowerResource *> *)fetchRequest;

@property (nonatomic) int32_t factionID;
@property (nonatomic) float minSecurityLevel;
@property (nonatomic) int32_t quantity;
@property (nonatomic) int32_t wormholeClassID;
@property (nullable, nonatomic, retain) NCDBInvControlTower *controlTower;
@property (nullable, nonatomic, retain) NCDBInvControlTowerResourcePurpose *purpose;
@property (nullable, nonatomic, retain) NCDBInvType *resourceType;

@end

NS_ASSUME_NONNULL_END
