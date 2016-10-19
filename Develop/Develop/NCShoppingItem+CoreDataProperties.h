//
//  NCShoppingItem+CoreDataProperties.h
//  Develop
//
//  Created by Artem Shimanski on 18.10.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCShoppingItem+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface NCShoppingItem (CoreDataProperties)

+ (NSFetchRequest<NCShoppingItem *> *)fetchRequest;

@property (nonatomic) BOOL finished;
@property (nonatomic) int32_t quantity;
@property (nonatomic) int32_t typeID;
@property (nullable, nonatomic, retain) NCShoppingGroup *shoppingGroup;

@end

NS_ASSUME_NONNULL_END
