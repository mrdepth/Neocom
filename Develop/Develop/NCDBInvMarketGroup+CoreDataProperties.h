//
//  NCDBInvMarketGroup+CoreDataProperties.h
//  Develop
//
//  Created by Artem Shimanski on 20.10.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCDBInvMarketGroup+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface NCDBInvMarketGroup (CoreDataProperties)

+ (NSFetchRequest<NCDBInvMarketGroup *> *)fetchRequest;

@property (nonatomic) int32_t marketGroupID;
@property (nullable, nonatomic, copy) NSString *marketGroupName;
@property (nullable, nonatomic, retain) NCDBEveIcon *icon;
@property (nullable, nonatomic, retain) NCDBInvMarketGroup *parentGroup;
@property (nullable, nonatomic, retain) NSSet<NCDBInvMarketGroup *> *subGroups;
@property (nullable, nonatomic, retain) NSSet<NCDBInvType *> *types;

@end

@interface NCDBInvMarketGroup (CoreDataGeneratedAccessors)

- (void)addSubGroupsObject:(NCDBInvMarketGroup *)value;
- (void)removeSubGroupsObject:(NCDBInvMarketGroup *)value;
- (void)addSubGroups:(NSSet<NCDBInvMarketGroup *> *)values;
- (void)removeSubGroups:(NSSet<NCDBInvMarketGroup *> *)values;

- (void)addTypesObject:(NCDBInvType *)value;
- (void)removeTypesObject:(NCDBInvType *)value;
- (void)addTypes:(NSSet<NCDBInvType *> *)values;
- (void)removeTypes:(NSSet<NCDBInvType *> *)values;

@end

NS_ASSUME_NONNULL_END
