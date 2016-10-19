//
//  NCCacheRecordData+CoreDataProperties.h
//  Develop
//
//  Created by Artem Shimanski on 18.10.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCCacheRecordData+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface NCCacheRecordData (CoreDataProperties)

+ (NSFetchRequest<NCCacheRecordData *> *)fetchRequest;

@property (nullable, nonatomic, retain) NSData *data;
@property (nullable, nonatomic, retain) NCCacheRecord *record;

@end

NS_ASSUME_NONNULL_END
