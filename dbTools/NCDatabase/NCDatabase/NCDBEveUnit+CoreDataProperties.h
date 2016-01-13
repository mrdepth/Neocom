//
//  NCDBEveUnit+CoreDataProperties.h
//  NCDatabase
//
//  Created by Артем Шиманский on 30.12.15.
//
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "NCDBEveUnit.h"

NS_ASSUME_NONNULL_BEGIN

@interface NCDBEveUnit (CoreDataProperties)

@property (nullable, nonatomic, retain) NSString *displayName;
@property (nonatomic) int32_t unitID;
@property (nullable, nonatomic, retain) NSSet<NCDBDgmAttributeType *> *attributeTypes;

@end

@interface NCDBEveUnit (CoreDataGeneratedAccessors)

- (void)addAttributeTypesObject:(NCDBDgmAttributeType *)value;
- (void)removeAttributeTypesObject:(NCDBDgmAttributeType *)value;
- (void)addAttributeTypes:(NSSet<NCDBDgmAttributeType *> *)values;
- (void)removeAttributeTypes:(NSSet<NCDBDgmAttributeType *> *)values;

@end

NS_ASSUME_NONNULL_END
