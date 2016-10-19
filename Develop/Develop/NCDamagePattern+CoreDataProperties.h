//
//  NCDamagePattern+CoreDataProperties.h
//  Develop
//
//  Created by Artem Shimanski on 18.10.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCDamagePattern+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface NCDamagePattern (CoreDataProperties)

+ (NSFetchRequest<NCDamagePattern *> *)fetchRequest;

@property (nonatomic) float em;
@property (nonatomic) float explosive;
@property (nonatomic) float kinetic;
@property (nullable, nonatomic, copy) NSString *name;
@property (nonatomic) float thermal;

@end

NS_ASSUME_NONNULL_END
