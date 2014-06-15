//
//  NCDBInvGroup.h
//  NCDatabase
//
//  Created by Shimanski Artem on 15.06.14.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class NCDBCertCertificate, NCDBEveIcon, NCDBInvCategory, NCDBInvType, NCDBNpcGroup;

@interface NCDBInvGroup : NSManagedObject

@property (nonatomic) int32_t groupID;
@property (nonatomic, retain) NSString * groupName;
@property (nonatomic) BOOL published;
@property (nonatomic, retain) NCDBInvCategory *category;
@property (nonatomic, retain) NCDBEveIcon *icon;
@property (nonatomic, retain) NSSet *npcGroups;
@property (nonatomic, retain) NSSet *types;
@property (nonatomic, retain) NSSet *certificates;
@end

@interface NCDBInvGroup (CoreDataGeneratedAccessors)

- (void)addNpcGroupsObject:(NCDBNpcGroup *)value;
- (void)removeNpcGroupsObject:(NCDBNpcGroup *)value;
- (void)addNpcGroups:(NSSet *)values;
- (void)removeNpcGroups:(NSSet *)values;

- (void)addTypesObject:(NCDBInvType *)value;
- (void)removeTypesObject:(NCDBInvType *)value;
- (void)addTypes:(NSSet *)values;
- (void)removeTypes:(NSSet *)values;

- (void)addCertificatesObject:(NCDBCertCertificate *)value;
- (void)removeCertificatesObject:(NCDBCertCertificate *)value;
- (void)addCertificates:(NSSet *)values;
- (void)removeCertificates:(NSSet *)values;

@end
