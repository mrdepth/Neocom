//
//  NCDBCertCertificate+CoreDataProperties.h
//  NCDatabase
//
//  Created by Artem Shimanski on 29.11.15.
//
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "NCDBCertCertificate.h"

NS_ASSUME_NONNULL_BEGIN

@interface NCDBCertCertificate (CoreDataProperties)

@property (nonatomic) int32_t certificateID;
@property (nullable, nonatomic, retain) NSString *certificateName;
@property (nullable, nonatomic, retain) NCDBTxtDescription *certificateDescription;
@property (nullable, nonatomic, retain) NCDBInvGroup *group;
@property (nullable, nonatomic, retain) NSOrderedSet<NCDBCertMastery *> *masteries;
@property (nullable, nonatomic, retain) NSSet<NCDBInvType *> *types;

@end

@interface NCDBCertCertificate (CoreDataGeneratedAccessors)

- (void)insertObject:(NCDBCertMastery *)value inMasteriesAtIndex:(NSUInteger)idx;
- (void)removeObjectFromMasteriesAtIndex:(NSUInteger)idx;
- (void)insertMasteries:(NSArray<NCDBCertMastery *> *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeMasteriesAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInMasteriesAtIndex:(NSUInteger)idx withObject:(NCDBCertMastery *)value;
- (void)replaceMasteriesAtIndexes:(NSIndexSet *)indexes withMasteries:(NSArray<NCDBCertMastery *> *)values;
- (void)addMasteriesObject:(NCDBCertMastery *)value;
- (void)removeMasteriesObject:(NCDBCertMastery *)value;
- (void)addMasteries:(NSOrderedSet<NCDBCertMastery *> *)values;
- (void)removeMasteries:(NSOrderedSet<NCDBCertMastery *> *)values;

- (void)addTypesObject:(NCDBInvType *)value;
- (void)removeTypesObject:(NCDBInvType *)value;
- (void)addTypes:(NSSet<NCDBInvType *> *)values;
- (void)removeTypes:(NSSet<NCDBInvType *> *)values;

@end

NS_ASSUME_NONNULL_END
