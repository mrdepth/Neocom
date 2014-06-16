//
//  NCDBInvControlTowerResource.h
//  Neocom
//
//  Created by Артем Шиманский on 16.06.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class NCDBInvControlTower, NCDBInvControlTowerResourcePurpose, NCDBInvType;

@interface NCDBInvControlTowerResource : NSManagedObject

@property (nonatomic) int32_t factionID;
@property (nonatomic) float minSecurityLevel;
@property (nonatomic) int32_t quantity;
@property (nonatomic) int32_t wormholeClassID;
@property (nonatomic, retain) NCDBInvControlTower *controlTower;
@property (nonatomic, retain) NCDBInvControlTowerResourcePurpose *purpose;
@property (nonatomic, retain) NCDBInvType *resourceType;

@end
