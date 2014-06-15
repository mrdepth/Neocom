//
//  NCDBDgmAttributeCategory.h
//  NCDatabase
//
//  Created by Shimanski Artem on 15.06.14.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class NCDBDgmAttributeType;

@interface NCDBDgmAttributeCategory : NSManagedObject

@property (nonatomic) int32_t categoryID;
@property (nonatomic, retain) NSString * categoryName;
@property (nonatomic, retain) NSSet *attributeTypes;
@end

@interface NCDBDgmAttributeCategory (CoreDataGeneratedAccessors)

- (void)addAttributeTypesObject:(NCDBDgmAttributeType *)value;
- (void)removeAttributeTypesObject:(NCDBDgmAttributeType *)value;
- (void)addAttributeTypes:(NSSet *)values;
- (void)removeAttributeTypes:(NSSet *)values;

@end
