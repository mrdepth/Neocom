//
//  NCDBDgmEffect+CoreDataProperties.h
//  Develop
//
//  Created by Artem Shimanski on 20.10.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCDBDgmEffect+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface NCDBDgmEffect (CoreDataProperties)

+ (NSFetchRequest<NCDBDgmEffect *> *)fetchRequest;

@property (nonatomic) int32_t effectID;
@property (nullable, nonatomic, retain) NSSet<NCDBInvType *> *types;

@end

@interface NCDBDgmEffect (CoreDataGeneratedAccessors)

- (void)addTypesObject:(NCDBInvType *)value;
- (void)removeTypesObject:(NCDBInvType *)value;
- (void)addTypes:(NSSet<NCDBInvType *> *)values;
- (void)removeTypes:(NSSet<NCDBInvType *> *)values;

@end

NS_ASSUME_NONNULL_END
