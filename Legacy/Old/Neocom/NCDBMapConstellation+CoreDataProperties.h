//
//  NCDBMapConstellation+CoreDataProperties.h
//  Neocom
//
//  Created by Artem Shimanski on 29.11.15.
//  Copyright © 2015 Artem Shimanski. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "NCDBMapConstellation.h"

NS_ASSUME_NONNULL_BEGIN

@interface NCDBMapConstellation (CoreDataProperties)

@property (nonatomic) int32_t constellationID;
@property (nullable, nonatomic, retain) NSString *constellationName;
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
