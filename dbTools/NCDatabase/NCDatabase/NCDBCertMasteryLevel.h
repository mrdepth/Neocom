//
//  NCDBCertMasteryLevel.h
//  NCDatabase
//
//  Created by Артем Шиманский on 15.05.14.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class NCDBCertMastery, NCDBEveIcon;

@interface NCDBCertMasteryLevel : NSManagedObject

@property (nonatomic) int16_t level;
@property (nonatomic, retain) NCDBEveIcon *unclaimedIcon;
@property (nonatomic, retain) NCDBEveIcon *claimedIcon;
@property (nonatomic, retain) NSSet *masteries;
@end

@interface NCDBCertMasteryLevel (CoreDataGeneratedAccessors)

- (void)addMasteriesObject:(NCDBCertMastery *)value;
- (void)removeMasteriesObject:(NCDBCertMastery *)value;
- (void)addMasteries:(NSSet *)values;
- (void)removeMasteries:(NSSet *)values;

@end
