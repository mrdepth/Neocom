//
//  NCDBDgmAttributeType+CoreDataProperties.h
//  Neocom
//
//  Created by Artem Shimanski on 29.11.15.
//  Copyright © 2015 Artem Shimanski. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "NCDBDgmAttributeType.h"

NS_ASSUME_NONNULL_BEGIN

@interface NCDBDgmAttributeType (CoreDataProperties)

@property (nonatomic) int32_t attributeID;
@property (nullable, nonatomic, retain) NSString *attributeName;
@property (nullable, nonatomic, retain) NSString *displayName;
@property (nonatomic) BOOL published;
@property (nullable, nonatomic, retain) NCDBDgmAttributeCategory *attributeCategory;
@property (nullable, nonatomic, retain) NCDBEveIcon *icon;
@property (nullable, nonatomic, retain) NSSet<NCDBDgmTypeAttribute *> *typeAttributes;
@property (nullable, nonatomic, retain) NCDBEveUnit *unit;

@end

@interface NCDBDgmAttributeType (CoreDataGeneratedAccessors)

- (void)addTypeAttributesObject:(NCDBDgmTypeAttribute *)value;
- (void)removeTypeAttributesObject:(NCDBDgmTypeAttribute *)value;
- (void)addTypeAttributes:(NSSet<NCDBDgmTypeAttribute *> *)values;
- (void)removeTypeAttributes:(NSSet<NCDBDgmTypeAttribute *> *)values;

@end

NS_ASSUME_NONNULL_END
