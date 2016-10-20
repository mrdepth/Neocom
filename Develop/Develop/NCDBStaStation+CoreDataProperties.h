//
//  NCDBStaStation+CoreDataProperties.h
//  Develop
//
//  Created by Artem Shimanski on 20.10.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCDBStaStation+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface NCDBStaStation (CoreDataProperties)

+ (NSFetchRequest<NCDBStaStation *> *)fetchRequest;

@property (nonatomic) float security;
@property (nonatomic) int32_t stationID;
@property (nullable, nonatomic, copy) NSString *stationName;
@property (nullable, nonatomic, retain) NCDBMapSolarSystem *solarSystem;
@property (nullable, nonatomic, retain) NCDBInvType *stationType;

@end

NS_ASSUME_NONNULL_END
