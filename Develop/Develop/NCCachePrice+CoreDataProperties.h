//
//  NCCachePrice+CoreDataProperties.h
//  Develop
//
//  Created by Artem Shimanski on 20.10.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCCachePrice+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface NCCachePrice (CoreDataProperties)

+ (NSFetchRequest<NCCachePrice *> *)fetchRequest;

@property (nonatomic) double price;
@property (nonatomic) int32_t typeID;

@end

NS_ASSUME_NONNULL_END
