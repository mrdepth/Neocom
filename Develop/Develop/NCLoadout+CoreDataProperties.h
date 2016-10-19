//
//  NCLoadout+CoreDataProperties.h
//  Develop
//
//  Created by Artem Shimanski on 18.10.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCLoadout+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface NCLoadout (CoreDataProperties)

+ (NSFetchRequest<NCLoadout *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSString *name;
@property (nullable, nonatomic, copy) NSString *tag;
@property (nonatomic) int32_t typeID;
@property (nullable, nonatomic, copy) NSString *url;
@property (nullable, nonatomic, retain) NCLoadoutData *data;

@end

NS_ASSUME_NONNULL_END
