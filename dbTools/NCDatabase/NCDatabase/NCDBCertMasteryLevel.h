//
//  NCDBCertMasteryLevel.h
//  NCDatabase
//
//  Created by Артем Шиманский on 18.06.14.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class NCDBCertMastery, NCDBEveIcon;

@interface NCDBCertMasteryLevel : NSManagedObject

@property (nonatomic, retain) NSString * displayName;
@property (nonatomic) int16_t level;
@property (nonatomic, retain) NCDBEveIcon *icon;
@property (nonatomic, retain) NSSet *masteries;
@end

@interface NCDBCertMasteryLevel (CoreDataGeneratedAccessors)

- (void)addMasteriesObject:(NCDBCertMastery *)value;
- (void)removeMasteriesObject:(NCDBCertMastery *)value;
- (void)addMasteries:(NSSet *)values;
- (void)removeMasteries:(NSSet *)values;

@end
