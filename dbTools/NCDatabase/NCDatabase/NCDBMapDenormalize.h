//
//  NCDBMapDenormalize.h
//  NCDatabase
//
//  Created by Артем Шиманский on 15.05.14.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class NCDBInvType, NCDBMapConstellation, NCDBMapRegion, NCDBMapSolarSystem;

@interface NCDBMapDenormalize : NSManagedObject

@property (nonatomic) int32_t itemID;
@property (nonatomic, retain) NSString * itemName;
@property (nonatomic) float security;
@property (nonatomic, retain) NCDBMapConstellation *constellation;
@property (nonatomic, retain) NCDBMapRegion *region;
@property (nonatomic, retain) NCDBMapSolarSystem *solarSystem;
@property (nonatomic, retain) NCDBInvType *type;

@end
