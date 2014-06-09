//
//  NCDBInvMarketGroup.h
//  NCDatabase
//
//  Created by Артем Шиманский on 15.05.14.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class NCDBEveIcon, NCDBInvMarketGroup, NCDBInvType;

@interface NCDBInvMarketGroup : NSManagedObject

@property (nonatomic) int32_t marketGroupID;
@property (nonatomic, retain) NCDBEveIcon *icon;
@property (nonatomic, retain) NCDBInvMarketGroup *parentGroup;
@property (nonatomic, retain) NSSet *subGroups;
@property (nonatomic, retain) NSSet *types;
@end

@interface NCDBInvMarketGroup (CoreDataGeneratedAccessors)

- (void)addSubGroupsObject:(NCDBInvMarketGroup *)value;
- (void)removeSubGroupsObject:(NCDBInvMarketGroup *)value;
- (void)addSubGroups:(NSSet *)values;
- (void)removeSubGroups:(NSSet *)values;

- (void)addTypesObject:(NCDBInvType *)value;
- (void)removeTypesObject:(NCDBInvType *)value;
- (void)addTypes:(NSSet *)values;
- (void)removeTypes:(NSSet *)values;

@end
