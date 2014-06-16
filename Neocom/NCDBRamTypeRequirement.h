//
//  NCDBRamTypeRequirement.h
//  Neocom
//
//  Created by Артем Шиманский on 16.06.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class NCDBInvType, NCDBRamActivity;

@interface NCDBRamTypeRequirement : NSManagedObject

@property (nonatomic) float damagePerJob;
@property (nonatomic) int32_t quantity;
@property (nonatomic) int32_t recycle;
@property (nonatomic, retain) NCDBRamActivity *activity;
@property (nonatomic, retain) NCDBInvType *requiredType;
@property (nonatomic, retain) NCDBInvType *type;

@end
