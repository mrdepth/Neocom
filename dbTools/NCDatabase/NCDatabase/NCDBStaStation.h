//
//  NCDBStaStation.h
//  NCDatabase
//
//  Created by Артем Шиманский on 15.05.14.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class NCDBInvType, NCDBMapSolarSystem;

@interface NCDBStaStation : NSManagedObject

@property (nonatomic) int32_t stationID;
@property (nonatomic) float security;
@property (nonatomic, retain) NSString * stationName;
@property (nonatomic, retain) NCDBInvType *stationType;
@property (nonatomic, retain) NCDBMapSolarSystem *solarSystem;

@end
