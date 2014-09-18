//
//  NCDBIndProduct.h
//  Neocom
//
//  Created by Артем Шиманский on 18.09.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class NCDBChrRace, NCDBIndActivity, NCDBInvType;

@interface NCDBIndProduct : NSManagedObject

@property (nonatomic) float probability;
@property (nonatomic) int32_t quantity;
@property (nonatomic, retain) NCDBIndActivity *activity;
@property (nonatomic, retain) NCDBInvType *productType;
@property (nonatomic, retain) NCDBChrRace *race;

@end
