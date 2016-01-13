//
//  NCDBDgmppHullType+CoreDataProperties.h
//  NCDatabase
//
//  Created by Артем Шиманский on 30.12.15.
//
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "NCDBDgmppHullType.h"

NS_ASSUME_NONNULL_BEGIN

@interface NCDBDgmppHullType (CoreDataProperties)

@property (nullable, nonatomic, retain) NSString *hullTypeName;
@property (nonatomic) float signature;
@property (nullable, nonatomic, retain) NSSet<NCDBInvType *> *types;

@end

@interface NCDBDgmppHullType (CoreDataGeneratedAccessors)

- (void)addTypesObject:(NCDBInvType *)value;
- (void)removeTypesObject:(NCDBInvType *)value;
- (void)addTypes:(NSSet<NCDBInvType *> *)values;
- (void)removeTypes:(NSSet<NCDBInvType *> *)values;

@end

NS_ASSUME_NONNULL_END
