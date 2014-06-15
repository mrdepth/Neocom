//
//  NCDBMapDenormalize.h
//  Neocom
//
//  Created by Shimanski Artem on 15.06.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class NCDBInvType, NCDBMapConstellation, NCDBMapRegion, NCDBMapSolarSystem;

@interface NCDBMapDenormalize : NSManagedObject

@property (nonatomic) int32_t itemID;
@property (nonatomic, retain) NSString * itemName;
@property (nonatomic) float security;
@property (nonatomic, retain) NCDBMapConstellation *constellation;
@property (nonatomic, retain) NCDBMapRegion *region;
@property (nonatomic, retain) NCDBMapSolarSystem *solarSystem;
@property (nonatomic, retain) NCDBInvType *type;

@end
