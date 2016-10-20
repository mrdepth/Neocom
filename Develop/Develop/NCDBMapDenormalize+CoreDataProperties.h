//
//  NCDBMapDenormalize+CoreDataProperties.h
//  Develop
//
//  Created by Artem Shimanski on 20.10.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCDBMapDenormalize+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface NCDBMapDenormalize (CoreDataProperties)

+ (NSFetchRequest<NCDBMapDenormalize *> *)fetchRequest;

@property (nonatomic) int32_t itemID;
@property (nullable, nonatomic, copy) NSString *itemName;
@property (nonatomic) float security;
@property (nullable, nonatomic, retain) NCDBMapConstellation *constellation;
@property (nullable, nonatomic, retain) NCDBMapRegion *region;
@property (nullable, nonatomic, retain) NCDBMapSolarSystem *solarSystem;
@property (nullable, nonatomic, retain) NCDBInvType *type;

@end

NS_ASSUME_NONNULL_END
