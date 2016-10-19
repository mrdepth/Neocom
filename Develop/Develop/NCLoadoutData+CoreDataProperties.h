//
//  NCLoadoutData+CoreDataProperties.h
//  Develop
//
//  Created by Artem Shimanski on 18.10.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCLoadoutData+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface NCLoadoutData (CoreDataProperties)

+ (NSFetchRequest<NCLoadoutData *> *)fetchRequest;

@property (nullable, nonatomic, retain) NSObject *data;
@property (nullable, nonatomic, retain) NCLoadout *loadout;

@end

NS_ASSUME_NONNULL_END
