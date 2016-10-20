//
//  NCDBMapConstellation+CoreDataProperties.h
//  Develop
//
//  Created by Artem Shimanski on 20.10.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCDBMapConstellation+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface NCDBMapConstellation (CoreDataProperties)

+ (NSFetchRequest<NCDBMapConstellation *> *)fetchRequest;

@property (nonatomic) int32_t constellationID;
@property (nullable, nonatomic, copy) NSString *constellationName;
@property (nonatomic) int32_t factionID;
@property (nullable, nonatomic, retain) NSSet<NCDBMapDenormalize *> *denormalize;
@property (nullable, nonatomic, retain) NCDBMapRegion *region;
@property (nullable, nonatomic, retain) NSSet<NCDBMapSolarSystem *> *solarSystems;

@end

@interface NCDBMapConstellation (CoreDataGeneratedAccessors)

- (void)addDenormalizeObject:(NCDBMapDenormalize *)value;
- (void)removeDenormalizeObject:(NCDBMapDenormalize *)value;
- (void)addDenormalize:(NSSet<NCDBMapDenormalize *> *)values;
- (void)removeDenormalize:(NSSet<NCDBMapDenormalize *> *)values;

- (void)addSolarSystemsObject:(NCDBMapSolarSystem *)value;
- (void)removeSolarSystemsObject:(NCDBMapSolarSystem *)value;
- (void)addSolarSystems:(NSSet<NCDBMapSolarSystem *> *)values;
- (void)removeSolarSystems:(NSSet<NCDBMapSolarSystem *> *)values;

@end

NS_ASSUME_NONNULL_END
