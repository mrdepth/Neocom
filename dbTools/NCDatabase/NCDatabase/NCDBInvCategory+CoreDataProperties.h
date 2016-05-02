//
//  NCDBInvCategory+CoreDataProperties.h
//  NCDatabase
//
//  Created by Артем Шиманский on 14.03.16.
//
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "NCDBInvCategory.h"

NS_ASSUME_NONNULL_BEGIN

@interface NCDBInvCategory (CoreDataProperties)

@property (nonatomic) int32_t categoryID;
@property (nullable, nonatomic, retain) NSString *categoryName;
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
