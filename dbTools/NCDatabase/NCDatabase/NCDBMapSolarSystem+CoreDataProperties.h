//
//  NCDBMapSolarSystem+CoreDataProperties.h
//  NCDatabase
//
//  Created by Артем Шиманский on 30.12.15.
//
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "NCDBMapSolarSystem.h"

NS_ASSUME_NONNULL_BEGIN

@interface NCDBMapSolarSystem (CoreDataProperties)

@property (nonatomic) int32_t factionID;
@property (nonatomic) float security;
@property (nonatomic) int32_t solarSystemID;
@property (nullable, nonatomic, retain) NSString *solarSystemName;
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
