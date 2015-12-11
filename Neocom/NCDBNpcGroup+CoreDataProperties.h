//
//  NCDBNpcGroup+CoreDataProperties.h
//  Neocom
//
//  Created by Artem Shimanski on 29.11.15.
//  Copyright © 2015 Artem Shimanski. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "NCDBNpcGroup.h"

NS_ASSUME_NONNULL_BEGIN

@interface NCDBNpcGroup (CoreDataProperties)

@property (nullable, nonatomic, retain) NSString *npcGroupName;
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
