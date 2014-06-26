//
//  NCDBStaStation.h
//  NCDatabase
//
//  Created by Артем Шиманский on 19.06.14.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class NCDBInvType, NCDBMapSolarSystem;

@interface NCDBStaStation : NSManagedObject

@property (nonatomic) float security;
@property (nonatomic) int32_t stationID;
@property (nonatomic, retain) NSString * stationName;
@property (nonatomic, retain) NCDBMapSolarSystem *solarSystem;
@property (nonatomic, retain) NCDBInvType *stationType;

@end
