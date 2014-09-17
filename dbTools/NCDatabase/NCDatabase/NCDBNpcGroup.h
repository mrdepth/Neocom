//
//  NCDBNpcGroup.h
//  NCDatabase
//
//  Created by Артем Шиманский on 17.09.14.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class NCDBEveIcon, NCDBInvGroup, NCDBNpcGroup;

@interface NCDBNpcGroup : NSManagedObject

@property (nonatomic, retain) NSString * npcGroupName;
@property (nonatomic, retain) NCDBInvGroup *group;
@property (nonatomic, retain) NCDBEveIcon *icon;
@property (nonatomic, retain) NCDBNpcGroup *parentNpcGroup;
@property (nonatomic, retain) NSSet *supNpcGroups;
@end

@interface NCDBNpcGroup (CoreDataGeneratedAccessors)

- (void)addSupNpcGroupsObject:(NCDBNpcGroup *)value;
- (void)removeSupNpcGroupsObject:(NCDBNpcGroup *)value;
- (void)addSupNpcGroups:(NSSet *)values;
- (void)removeSupNpcGroups:(NSSet *)values;

@end
