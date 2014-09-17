//
//  NCDBEufeItemGroup.h
//  NCDatabase
//
//  Created by Артем Шиманский on 17.09.14.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class NCDBEufeItem, NCDBEufeItemCategory, NCDBEufeItemGroup, NCDBEveIcon;

@interface NCDBEufeItemGroup : NSManagedObject

@property (nonatomic, retain) NSString * groupName;
@property (nonatomic, retain) NCDBEufeItemCategory *category;
@property (nonatomic, retain) NCDBEveIcon *icon;
@property (nonatomic, retain) NSSet *items;
@property (nonatomic, retain) NCDBEufeItemGroup *parentGroup;
@property (nonatomic, retain) NSSet *subGroups;
@end

@interface NCDBEufeItemGroup (CoreDataGeneratedAccessors)

- (void)addItemsObject:(NCDBEufeItem *)value;
- (void)removeItemsObject:(NCDBEufeItem *)value;
- (void)addItems:(NSSet *)values;
- (void)removeItems:(NSSet *)values;

- (void)addSubGroupsObject:(NCDBEufeItemGroup *)value;
- (void)removeSubGroupsObject:(NCDBEufeItemGroup *)value;
- (void)addSubGroups:(NSSet *)values;
- (void)removeSubGroups:(NSSet *)values;

@end
