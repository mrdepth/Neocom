//
//  NCDBInvCategory.h
//  Neocom
//
//  Created by Артем Шиманский on 16.06.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class NCDBEveIcon, NCDBInvGroup;

@interface NCDBInvCategory : NSManagedObject

@property (nonatomic) int32_t categoryID;
@property (nonatomic, retain) NSString * categoryName;
@property (nonatomic) BOOL published;
@property (nonatomic, retain) NSSet *groups;
@property (nonatomic, retain) NCDBEveIcon *icon;
@end

@interface NCDBInvCategory (CoreDataGeneratedAccessors)

- (void)addGroupsObject:(NCDBInvGroup *)value;
- (void)removeGroupsObject:(NCDBInvGroup *)value;
- (void)addGroups:(NSSet *)values;
- (void)removeGroups:(NSSet *)values;

@end
