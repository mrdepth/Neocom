//
//  NCDBMapRegion+CoreDataProperties.h
//  NCDatabase
//
//  Created by Artem Shimanski on 29.11.15.
//
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "NCDBMapRegion.h"

NS_ASSUME_NONNULL_BEGIN

@interface NCDBMapRegion (CoreDataProperties)

@property (nonatomic) int32_t factionID;
@property (nonatomic) int32_t regionID;
@property (nullable, nonatomic, retain) NSString *regionName;
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
