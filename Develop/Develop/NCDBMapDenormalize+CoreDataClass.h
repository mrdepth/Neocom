//
//  NCDBMapDenormalize+CoreDataClass.h
//  Develop
//
//  Created by Artem Shimanski on 20.10.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class NCDBInvType, NCDBMapConstellation, NCDBMapRegion, NCDBMapSolarSystem;

NS_ASSUME_NONNULL_BEGIN

@interface NCDBMapDenormalize : NSManagedObject

@end

NS_ASSUME_NONNULL_END

#import "NCDBMapDenormalize+CoreDataProperties.h"
