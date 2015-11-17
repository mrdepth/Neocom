//
//  NCCachePrice.h
//  Neocom
//
//  Created by Артем Шиманский on 17.07.15.
//  Copyright (c) 2015 Artem Shimanski. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface NCCachePrice : NSManagedObject

@property (nonatomic) int32_t typeID;
@property (nonatomic) double price;

@end
