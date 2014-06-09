//
//  NCDBInvGroup.h
//  NCDatabase
//
//  Created by Артем Шиманский on 15.05.14.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class NCDBEveIcon, NCDBInvCategory, NCDBInvType, NCDBNpcGroup;

@interface NCDBInvGroup : NSManagedObject

@property (nonatomic) int32_t groupID;
@property (nonatomic, retain) NCDBInvCategory *category;
@property (nonatomic, retain) NCDBEveIcon *icon;
@property (nonatomic, retain) NSSet *npcGroups;
@property (nonatomic, retain) NSSet *types;
@end

@interface NCDBInvGroup (CoreDataGeneratedAccessors)

- (void)addNpcGroupsObject:(NCDBNpcGroup *)value;
- (void)removeNpcGroupsObject:(NCDBNpcGroup *)value;
- (void)addNpcGroups:(NSSet *)values;
- (void)removeNpcGroups:(NSSet *)values;

- (void)addTypesObject:(NCDBInvType *)value;
- (void)removeTypesObject:(NCDBInvType *)value;
- (void)addTypes:(NSSet *)values;
- (void)removeTypes:(NSSet *)values;

@end
