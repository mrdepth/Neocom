//
//  NCDBCertCertificate.h
//  NCDatabase
//
//  Created by Артем Шиманский on 15.05.14.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class NCDBCertMastery;

@interface NCDBCertCertificate : NSManagedObject

@property (nonatomic) int32_t certificateID;
@property (nonatomic, retain) NSSet *masteries;
@end

@interface NCDBCertCertificate (CoreDataGeneratedAccessors)

- (void)addMasteriesObject:(NCDBCertMastery *)value;
- (void)removeMasteriesObject:(NCDBCertMastery *)value;
- (void)addMasteries:(NSSet *)values;
- (void)removeMasteries:(NSSet *)values;

@end
