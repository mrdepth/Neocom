//
//  NCDronesSet+CoreDataProperties.h
//  Develop
//
//  Created by Artem Shimanski on 18.10.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCDronesSet+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface NCDronesSet (CoreDataProperties)

+ (NSFetchRequest<NCDronesSet *> *)fetchRequest;

@property (nullable, nonatomic, retain) NSObject *data;
@property (nullable, nonatomic, copy) NSString *name;

@end

NS_ASSUME_NONNULL_END
