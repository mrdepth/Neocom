//
//  NCDBMapDenormalize.h
//  NCDatabase
//
//  Created by Artem Shimanski on 29.11.15.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class NCDBInvType, NCDBMapConstellation, NCDBMapRegion, NCDBMapSolarSystem;

NS_ASSUME_NONNULL_BEGIN

@interface NCDBMapDenormalize : NSManagedObject

// Insert code here to declare functionality of your managed object subclass

@end

NS_ASSUME_NONNULL_END

#import "NCDBMapDenormalize+CoreDataProperties.h"
