//
//  NCDBIndProduct+CoreDataProperties.h
//  Develop
//
//  Created by Artem Shimanski on 20.10.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCDBIndProduct+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface NCDBIndProduct (CoreDataProperties)

+ (NSFetchRequest<NCDBIndProduct *> *)fetchRequest;

@property (nonatomic) float probability;
@property (nonatomic) int32_t quantity;
@property (nullable, nonatomic, retain) NCDBIndActivity *activity;
@property (nullable, nonatomic, retain) NCDBInvType *productType;

@end

NS_ASSUME_NONNULL_END
