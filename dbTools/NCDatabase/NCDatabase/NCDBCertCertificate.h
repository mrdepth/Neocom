//
//  NCDBCertCertificate.h
//  NCDatabase
//
//  Created by Артем Шиманский on 18.06.14.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class NCDBCertMastery, NCDBInvGroup, NCDBInvType, NCDBTxtDescription;

@interface NCDBCertCertificate : NSManagedObject

@property (nonatomic) int32_t certificateID;
@property (nonatomic, retain) NSString * certificateName;
@property (nonatomic, retain) NCDBTxtDescription *certificateDescription;
@property (nonatomic, retain) NCDBInvGroup *group;
@property (nonatomic, retain) NSOrderedSet *masteries;
@property (nonatomic, retain) NSSet *types;
@end

@interface NCDBCertCertificate (CoreDataGeneratedAccessors)

- (void)insertObject:(NCDBCertMastery *)value inMasteriesAtIndex:(NSUInteger)idx;
- (void)removeObjectFromMasteriesAtIndex:(NSUInteger)idx;
- (void)insertMasteries:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeMasteriesAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInMasteriesAtIndex:(NSUInteger)idx withObject:(NCDBCertMastery *)value;
- (void)replaceMasteriesAtIndexes:(NSIndexSet *)indexes withMasteries:(NSArray *)values;
- (void)addMasteriesObject:(NCDBCertMastery *)value;
- (void)removeMasteriesObject:(NCDBCertMastery *)value;
- (void)addMasteries:(NSOrderedSet *)values;
- (void)removeMasteries:(NSOrderedSet *)values;
- (void)addTypesObject:(NCDBInvType *)value;
- (void)removeTypesObject:(NCDBInvType *)value;
- (void)addTypes:(NSSet *)values;
- (void)removeTypes:(NSSet *)values;

@end
