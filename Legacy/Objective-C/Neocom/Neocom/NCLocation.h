//
//  NCLocation.h
//  Neocom
//
//  Created by Artem Shimanski on 22.11.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import <Foundation/Foundation.h>

@class NCDBStaStation, NCDBMapSolarSystem, NCDBMapDenormalize, EVEConquerableStationListItem;
@interface NCLocation : NSObject
@property (nonatomic) int32_t stationID;
@property (nonatomic, strong) NSString *stationName;
@property (nonatomic) int32_t stationTypeID;
@property (nonatomic) int32_t solarSystemID;
@property (nonatomic, strong) NSString* solarSystemName;
@property (nonatomic) int32_t corporationID;
@property (nonatomic, strong) NSString *corporationName;
@property (nonatomic) float security;

- (instancetype) initWithStation:(NCDBStaStation*) station;
- (instancetype) initWithSolarSystem:(NCDBMapSolarSystem*) solarSystem;
- (instancetype) initWithMapDenormalize:(NCDBMapDenormalize*) mapDenormalize;
- (instancetype) initWithConquerableStation:(EVEConquerableStationListItem*) conquerableStation;
- (NSAttributedString*) displayName;
@end
