//
//  NCDBInvMetaGroup+CoreDataProperties.h
//  Develop
//
//  Created by Artem Shimanski on 20.10.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCDBInvMetaGroup+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface NCDBInvMetaGroup (CoreDataProperties)

+ (NSFetchRequest<NCDBInvMetaGroup *> *)fetchRequest;

@property (nonatomic) int32_t metaGroupID;
@property (nullable, nonatomic, copy) NSString *metaGroupName;
@property (nullable, nonatomic, retain) NCDBEveIcon *icon;
@property (nullable, nonatomic, retain) NSSet<NCDBInvType *> *types;

@end

@interface NCDBInvMetaGroup (CoreDataGeneratedAccessors)

- (void)addTypesObject:(NCDBInvType *)value;
- (void)removeTypesObject:(NCDBInvType *)value;
- (void)addTypes:(NSSet<NCDBInvType *> *)values;
- (void)removeTypes:(NSSet<NCDBInvType *> *)values;

@end

NS_ASSUME_NONNULL_END
