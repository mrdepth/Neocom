//
//  NCDBStaStation+CoreDataProperties.h
//  NCDatabase
//
//  Created by Артем Шиманский on 14.03.16.
//
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "NCDBStaStation.h"

NS_ASSUME_NONNULL_BEGIN

@interface NCDBStaStation (CoreDataProperties)

@property (nonatomic) float security;
@property (nonatomic) int32_t stationID;
@property (nullable, nonatomic, retain) NSString *stationName;
@property (nullable, nonatomic, retain) NCDBMapSolarSystem *solarSystem;
@property (nullable, nonatomic, retain) NCDBInvType *stationType;

@end

NS_ASSUME_NONNULL_END
