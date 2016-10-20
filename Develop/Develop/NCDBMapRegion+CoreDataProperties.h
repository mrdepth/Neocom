//
//  NCDBMapRegion+CoreDataProperties.h
//  Develop
//
//  Created by Artem Shimanski on 20.10.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCDBMapRegion+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface NCDBMapRegion (CoreDataProperties)

+ (NSFetchRequest<NCDBMapRegion *> *)fetchRequest;

@property (nonatomic) int32_t factionID;
@property (nonatomic) int32_t regionID;
@property (nullable, nonatomic, copy) NSString *regionName;
@property (nullable, nonatomic, retain) NSSet<NCDBMapConstellation *> *constellations;
@property (nullable, nonatomic, retain) NSSet<NCDBMapDenormalize *> *denormalize;

@end

@interface NCDBMapRegion (CoreDataGeneratedAccessors)

- (void)addConstellationsObject:(NCDBMapConstellation *)value;
- (void)removeConstellationsObject:(NCDBMapConstellation *)value;
- (void)addConstellations:(NSSet<NCDBMapConstellation *> *)values;
- (void)removeConstellations:(NSSet<NCDBMapConstellation *> *)values;

- (void)addDenormalizeObject:(NCDBMapDenormalize *)value;
- (void)removeDenormalizeObject:(NCDBMapDenormalize *)value;
- (void)addDenormalize:(NSSet<NCDBMapDenormalize *> *)values;
- (void)removeDenormalize:(NSSet<NCDBMapDenormalize *> *)values;

@end

NS_ASSUME_NONNULL_END
