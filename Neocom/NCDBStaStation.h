//
//  NCDBStaStation.h
//  Neocom
//
//  Created by Артем Шиманский on 18.06.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
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
