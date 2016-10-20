//
//  NCDBNpcGroup+CoreDataProperties.h
//  Develop
//
//  Created by Artem Shimanski on 20.10.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCDBNpcGroup+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface NCDBNpcGroup (CoreDataProperties)

+ (NSFetchRequest<NCDBNpcGroup *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSString *npcGroupName;
@property (nullable, nonatomic, retain) NCDBInvGroup *group;
@property (nullable, nonatomic, retain) NCDBEveIcon *icon;
@property (nullable, nonatomic, retain) NCDBNpcGroup *parentNpcGroup;
@property (nullable, nonatomic, retain) NSSet<NCDBNpcGroup *> *supNpcGroups;

@end

@interface NCDBNpcGroup (CoreDataGeneratedAccessors)

- (void)addSupNpcGroupsObject:(NCDBNpcGroup *)value;
- (void)removeSupNpcGroupsObject:(NCDBNpcGroup *)value;
- (void)addSupNpcGroups:(NSSet<NCDBNpcGroup *> *)values;
- (void)removeSupNpcGroups:(NSSet<NCDBNpcGroup *> *)values;

@end

NS_ASSUME_NONNULL_END
