//
//  NCSetting+CoreDataProperties.h
//  Develop
//
//  Created by Artem Shimanski on 18.10.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCSetting+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface NCSetting (CoreDataProperties)

+ (NSFetchRequest<NCSetting *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSString *key;
@property (nullable, nonatomic, retain) NSObject *value;

@end

NS_ASSUME_NONNULL_END
