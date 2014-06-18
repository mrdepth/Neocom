//
//  NCDBEufeItem.h
//  Neocom
//
//  Created by Артем Шиманский on 18.06.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class NCDBEufeItemCategory, NCDBEufeItemGroup, NCDBInvType;

@interface NCDBEufeItem : NSManagedObject

@property (nonatomic, retain) NSSet *groups;
@property (nonatomic, retain) NCDBInvType *type;
@property (nonatomic, retain) NCDBEufeItemCategory *charge;
@end

@interface NCDBEufeItem (CoreDataGeneratedAccessors)

- (void)addGroupsObject:(NCDBEufeItemGroup *)value;
- (void)removeGroupsObject:(NCDBEufeItemGroup *)value;
- (void)addGroups:(NSSet *)values;
- (void)removeGroups:(NSSet *)values;

@end
