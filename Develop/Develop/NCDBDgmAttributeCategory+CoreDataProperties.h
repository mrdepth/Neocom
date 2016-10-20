//
//  NCDBDgmAttributeCategory+CoreDataProperties.h
//  Develop
//
//  Created by Artem Shimanski on 20.10.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCDBDgmAttributeCategory+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface NCDBDgmAttributeCategory (CoreDataProperties)

+ (NSFetchRequest<NCDBDgmAttributeCategory *> *)fetchRequest;

@property (nonatomic) int32_t categoryID;
@property (nullable, nonatomic, copy) NSString *categoryName;
@property (nullable, nonatomic, retain) NSSet<NCDBDgmAttributeType *> *attributeTypes;

@end

@interface NCDBDgmAttributeCategory (CoreDataGeneratedAccessors)

- (void)addAttributeTypesObject:(NCDBDgmAttributeType *)value;
- (void)removeAttributeTypesObject:(NCDBDgmAttributeType *)value;
- (void)addAttributeTypes:(NSSet<NCDBDgmAttributeType *> *)values;
- (void)removeAttributeTypes:(NSSet<NCDBDgmAttributeType *> *)values;

@end

NS_ASSUME_NONNULL_END
