//
//  NCDBEufeItemCategory.h
//  NCDatabase
//
//  Created by Артем Шиманский on 18.06.14.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class NCDBChrRace, NCDBEufeItem, NCDBEufeItemGroup;

@interface NCDBEufeItemCategory : NSManagedObject

@property (nonatomic) int16_t slot;
@property (nonatomic) int16_t size;
@property (nonatomic, retain) NSSet *itemGroups;
@property (nonatomic, retain) NCDBChrRace *race;
@property (nonatomic, retain) NSSet *eufeItems;
@end

@interface NCDBEufeItemCategory (CoreDataGeneratedAccessors)

- (void)addItemGroupsObject:(NCDBEufeItemGroup *)value;
- (void)removeItemGroupsObject:(NCDBEufeItemGroup *)value;
- (void)addItemGroups:(NSSet *)values;
- (void)removeItemGroups:(NSSet *)values;

- (void)addEufeItemsObject:(NCDBEufeItem *)value;
- (void)removeEufeItemsObject:(NCDBEufeItem *)value;
- (void)addEufeItems:(NSSet *)values;
- (void)removeEufeItems:(NSSet *)values;

@end
