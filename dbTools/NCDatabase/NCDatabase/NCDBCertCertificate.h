//
//  NCDBCertCertificate.h
//  NCDatabase
//
//  Created by Shimanski Artem on 15.06.14.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class NCDBCertMastery, NCDBInvGroup, NCDBTxtDescription;

@interface NCDBCertCertificate : NSManagedObject

@property (nonatomic) int32_t certificateID;
@property (nonatomic, retain) NSString * certificateName;
@property (nonatomic, retain) NCDBTxtDescription *certificateDescription;
@property (nonatomic, retain) NSSet *masteries;
@property (nonatomic, retain) NCDBInvGroup *group;
@end

@interface NCDBCertCertificate (CoreDataGeneratedAccessors)

- (void)addMasteriesObject:(NCDBCertMastery *)value;
- (void)removeMasteriesObject:(NCDBCertMastery *)value;
- (void)addMasteries:(NSSet *)values;
- (void)removeMasteries:(NSSet *)values;

@end
