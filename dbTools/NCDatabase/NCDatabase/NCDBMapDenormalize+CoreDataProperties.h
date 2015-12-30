//
//  NCDBMapDenormalize+CoreDataProperties.h
//  NCDatabase
//
//  Created by Артем Шиманский on 30.12.15.
//
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "NCDBMapDenormalize.h"

NS_ASSUME_NONNULL_BEGIN

@interface NCDBMapDenormalize (CoreDataProperties)

@property (nonatomic) int32_t itemID;
@property (nullable, nonatomic, retain) NSString *itemName;
@property (nonatomic) float security;
@property (nullable, nonatomic, retain) NCDBMapConstellation *constellation;
@property (nullable, nonatomic, retain) NCDBMapRegion *region;
@property (nullable, nonatomic, retain) NCDBMapSolarSystem *solarSystem;
@property (nullable, nonatomic, retain) NCDBInvType *type;

@end

NS_ASSUME_NONNULL_END
