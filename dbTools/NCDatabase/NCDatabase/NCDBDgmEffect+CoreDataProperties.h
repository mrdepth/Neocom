//
//  NCDBDgmEffect+CoreDataProperties.h
//  NCDatabase
//
//  Created by Artem Shimanski on 29.11.15.
//
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "NCDBDgmEffect.h"

NS_ASSUME_NONNULL_BEGIN

@interface NCDBDgmEffect (CoreDataProperties)

@property (nonatomic) int32_t effectID;
@property (nullable, nonatomic, retain) NSSet<NCDBInvType *> *types;

@end

@interface NCDBDgmEffect (CoreDataGeneratedAccessors)

- (void)addTypesObject:(NCDBInvType *)value;
- (void)removeTypesObject:(NCDBInvType *)value;
- (void)addTypes:(NSSet<NCDBInvType *> *)values;
- (void)removeTypes:(NSSet<NCDBInvType *> *)values;

@end

NS_ASSUME_NONNULL_END
