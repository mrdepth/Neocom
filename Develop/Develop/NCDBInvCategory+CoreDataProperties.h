//
//  NCDBInvCategory+CoreDataProperties.h
//  Develop
//
//  Created by Artem Shimanski on 20.10.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCDBInvCategory+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface NCDBInvCategory (CoreDataProperties)

+ (NSFetchRequest<NCDBInvCategory *> *)fetchRequest;

@property (nonatomic) int32_t categoryID;
@property (nullable, nonatomic, copy) NSString *categoryName;
@property (nonatomic) BOOL published;
@property (nullable, nonatomic, retain) NSSet<NCDBInvGroup *> *groups;
@property (nullable, nonatomic, retain) NCDBEveIcon *icon;

@end

@interface NCDBInvCategory (CoreDataGeneratedAccessors)

- (void)addGroupsObject:(NCDBInvGroup *)value;
- (void)removeGroupsObject:(NCDBInvGroup *)value;
- (void)addGroups:(NSSet<NCDBInvGroup *> *)values;
- (void)removeGroups:(NSSet<NCDBInvGroup *> *)values;

@end

NS_ASSUME_NONNULL_END
