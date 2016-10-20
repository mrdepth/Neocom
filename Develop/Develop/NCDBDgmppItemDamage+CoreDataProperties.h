//
//  NCDBDgmppItemDamage+CoreDataProperties.h
//  Develop
//
//  Created by Artem Shimanski on 20.10.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCDBDgmppItemDamage+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface NCDBDgmppItemDamage (CoreDataProperties)

+ (NSFetchRequest<NCDBDgmppItemDamage *> *)fetchRequest;

@property (nonatomic) float emAmount;
@property (nonatomic) float explosiveAmount;
@property (nonatomic) float kineticAmount;
@property (nonatomic) float thermalAmount;
@property (nullable, nonatomic, retain) NCDBDgmppItem *item;

@end

NS_ASSUME_NONNULL_END
