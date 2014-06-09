//
//  NCDBInvControlTowerResource.h
//  NCDatabase
//
//  Created by Артем Шиманский on 15.05.14.
//
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
