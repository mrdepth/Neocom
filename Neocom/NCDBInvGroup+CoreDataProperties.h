//
//  NCDBInvGroup+CoreDataProperties.h
//  Neocom
//
//  Created by Artem Shimanski on 29.11.15.
//  Copyright © 2015 Artem Shimanski. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "NCDBInvGroup.h"

NS_ASSUME_NONNULL_BEGIN

@interface NCDBInvGroup (CoreDataProperties)

@property (nonatomic) int32_t groupID;
@property (nullable, nonatomic, retain) NSString *groupName;
@property (nonatomic) BOOL published;
@property (nullable, nonatomic, retain) NCDBInvCategory *category;
@property (nullable, nonatomic, retain) NSSet<NCDBCertCertificate *> *certificates;
@property (nullable, nonatomic, retain) NCDBEveIcon *icon;
@property (nullable, nonatomic, retain) NSSet<NCDBNpcGroup *> *npcGroups;
@property (nullable, nonatomic, retain) NSSet<NCDBInvType *> *types;

@end

@interface NCDBInvGroup (CoreDataGeneratedAccessors)

- (void)addCertificatesObject:(NCDBCertCertificate *)value;
- (void)removeCertificatesObject:(NCDBCertCertificate *)value;
- (void)addCertificates:(NSSet<NCDBCertCertificate *> *)values;
- (void)removeCertificates:(NSSet<NCDBCertCertificate *> *)values;

- (void)addNpcGroupsObject:(NCDBNpcGroup *)value;
- (void)removeNpcGroupsObject:(NCDBNpcGroup *)value;
- (void)addNpcGroups:(NSSet<NCDBNpcGroup *> *)values;
- (void)removeNpcGroups:(NSSet<NCDBNpcGroup *> *)values;

- (void)addTypesObject:(NCDBInvType *)value;
- (void)removeTypesObject:(NCDBInvType *)value;
- (void)addTypes:(NSSet<NCDBInvType *> *)values;
- (void)removeTypes:(NSSet<NCDBInvType *> *)values;

@end

NS_ASSUME_NONNULL_END
