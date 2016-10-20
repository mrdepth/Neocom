//
//  NCDBEveUnit+CoreDataProperties.h
//  Develop
//
//  Created by Artem Shimanski on 20.10.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCDBEveUnit+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface NCDBEveUnit (CoreDataProperties)

+ (NSFetchRequest<NCDBEveUnit *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSString *displayName;
@property (nonatomic) int32_t unitID;
@property (nullable, nonatomic, retain) NSSet<NCDBDgmAttributeType *> *attributeTypes;

@end

@interface NCDBEveUnit (CoreDataGeneratedAccessors)

- (void)addAttributeTypesObject:(NCDBDgmAttributeType *)value;
- (void)removeAttributeTypesObject:(NCDBDgmAttributeType *)value;
- (void)addAttributeTypes:(NSSet<NCDBDgmAttributeType *> *)values;
- (void)removeAttributeTypes:(NSSet<NCDBDgmAttributeType *> *)values;

@end

NS_ASSUME_NONNULL_END
