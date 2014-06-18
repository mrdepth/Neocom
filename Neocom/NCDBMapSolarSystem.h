//
//  NCDBMapSolarSystem.h
//  Neocom
//
//  Created by Артем Шиманский on 18.06.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class NCDBMapConstellation, NCDBMapDenormalize, NCDBStaStation;

@interface NCDBMapSolarSystem : NSManagedObject

@property (nonatomic) float security;
@property (nonatomic) int32_t solarSystemID;
@property (nonatomic, retain) NSString * solarSystemName;
@property (nonatomic, retain) NCDBMapConstellation *constellation;
@property (nonatomic, retain) NSSet *denormalize;
@property (nonatomic, retain) NSSet *stations;
@end

@interface NCDBMapSolarSystem (CoreDataGeneratedAccessors)

- (void)addDenormalizeObject:(NCDBMapDenormalize *)value;
- (void)removeDenormalizeObject:(NCDBMapDenormalize *)value;
- (void)addDenormalize:(NSSet *)values;
- (void)removeDenormalize:(NSSet *)values;

- (void)addStationsObject:(NCDBStaStation *)value;
- (void)removeStationsObject:(NCDBStaStation *)value;
- (void)addStations:(NSSet *)values;
- (void)removeStations:(NSSet *)values;

@end
