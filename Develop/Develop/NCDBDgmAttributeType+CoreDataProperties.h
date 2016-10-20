//
//  NCDBDgmAttributeType+CoreDataProperties.h
//  Develop
//
//  Created by Artem Shimanski on 20.10.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCDBDgmAttributeType+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface NCDBDgmAttributeType (CoreDataProperties)

+ (NSFetchRequest<NCDBDgmAttributeType *> *)fetchRequest;

@property (nonatomic) int32_t attributeID;
@property (nullable, nonatomic, copy) NSString *attributeName;
@property (nullable, nonatomic, copy) NSString *displayName;
@property (nonatomic) BOOL published;
@property (nullable, nonatomic, retain) NCDBDgmAttributeCategory *attributeCategory;
@property (nullable, nonatomic, retain) NCDBEveIcon *icon;
@property (nullable, nonatomic, retain) NSSet<NCDBDgmTypeAttribute *> *typeAttributes;
@property (nullable, nonatomic, retain) NCDBEveUnit *unit;

@end

@interface NCDBDgmAttributeType (CoreDataGeneratedAccessors)

- (void)addTypeAttributesObject:(NCDBDgmTypeAttribute *)value;
- (void)removeTypeAttributesObject:(NCDBDgmTypeAttribute *)value;
- (void)addTypeAttributes:(NSSet<NCDBDgmTypeAttribute *> *)values;
- (void)removeTypeAttributes:(NSSet<NCDBDgmTypeAttribute *> *)values;

@end

NS_ASSUME_NONNULL_END
