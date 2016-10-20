//
//  NCDBCertCertificate+CoreDataProperties.h
//  Develop
//
//  Created by Artem Shimanski on 20.10.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCDBCertCertificate+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface NCDBCertCertificate (CoreDataProperties)

+ (NSFetchRequest<NCDBCertCertificate *> *)fetchRequest;

@property (nonatomic) int32_t certificateID;
@property (nullable, nonatomic, copy) NSString *certificateName;
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
