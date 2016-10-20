//
//  NCDBMapSolarSystem+CoreDataProperties.h
//  Develop
//
//  Created by Artem Shimanski on 20.10.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCDBMapSolarSystem+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface NCDBMapSolarSystem (CoreDataProperties)

+ (NSFetchRequest<NCDBMapSolarSystem *> *)fetchRequest;

@property (nonatomic) int32_t factionID;
@property (nonatomic) float security;
@property (nonatomic) int32_t solarSystemID;
@property (nullable, nonatomic, copy) NSString *solarSystemName;
@property (nullable, nonatomic, retain) NCDBMapConstellation *constellation;
@property (nullable, nonatomic, retain) NSSet<NCDBMapDenormalize *> *denormalize;
@property (nullable, nonatomic, retain) NSSet<NCDBStaStation *> *stations;

@end

@interface NCDBMapSolarSystem (CoreDataGeneratedAccessors)

- (void)addDenormalizeObject:(NCDBMapDenormalize *)value;
- (void)removeDenormalizeObject:(NCDBMapDenormalize *)value;
- (void)addDenormalize:(NSSet<NCDBMapDenormalize *> *)values;
- (void)removeDenormalize:(NSSet<NCDBMapDenormalize *> *)values;

- (void)addStationsObject:(NCDBStaStation *)value;
- (void)removeStationsObject:(NCDBStaStation *)value;
- (void)addStations:(NSSet<NCDBStaStation *> *)values;
- (void)removeStations:(NSSet<NCDBStaStation *> *)values;

@end

NS_ASSUME_NONNULL_END
