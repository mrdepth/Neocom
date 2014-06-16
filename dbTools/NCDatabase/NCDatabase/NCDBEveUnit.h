//
//  NCDBEveUnit.h
//  NCDatabase
//
//  Created by Артем Шиманский on 16.06.14.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class NCDBDgmAttributeType;

@interface NCDBEveUnit : NSManagedObject

@property (nonatomic, retain) NSString * displayName;
@property (nonatomic) int32_t unitID;
@property (nonatomic, retain) NSSet *attributeTypes;
@end

@interface NCDBEveUnit (CoreDataGeneratedAccessors)

- (void)addAttributeTypesObject:(NCDBDgmAttributeType *)value;
- (void)removeAttributeTypesObject:(NCDBDgmAttributeType *)value;
- (void)addAttributeTypes:(NSSet *)values;
- (void)removeAttributeTypes:(NSSet *)values;

@end
