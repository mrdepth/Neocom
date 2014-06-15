//
//  NCDBInvMarketGroup.h
//  Neocom
//
//  Created by Shimanski Artem on 15.06.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class NCDBEveIcon, NCDBInvMarketGroup, NCDBInvType;

@interface NCDBInvMarketGroup : NSManagedObject

@property (nonatomic) int32_t marketGroupID;
@property (nonatomic, retain) NSString * marketGroupName;
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
