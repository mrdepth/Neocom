//
//  NCDBVersion+CoreDataProperties.h
//  Develop
//
//  Created by Artem Shimanski on 20.10.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCDBVersion+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface NCDBVersion (CoreDataProperties)

+ (NSFetchRequest<NCDBVersion *> *)fetchRequest;

@property (nonatomic) int32_t build;
@property (nullable, nonatomic, copy) NSString *expansion;
@property (nullable, nonatomic, copy) NSString *version;

@end

NS_ASSUME_NONNULL_END
