//
//  NCDBCertMasteryLevel+CoreDataProperties.h
//  NCDatabase
//
//  Created by Артем Шиманский on 14.03.16.
//
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "NCDBCertMasteryLevel.h"

NS_ASSUME_NONNULL_BEGIN

@interface NCDBCertMasteryLevel (CoreDataProperties)

@property (nullable, nonatomic, retain) NSString *displayName;
@property (nonatomic) int16_t level;
@property (nullable, nonatomic, retain) NCDBEveIcon *icon;
@property (nullable, nonatomic, retain) NSSet<NCDBCertMastery *> *masteries;

@end

@interface NCDBCertMasteryLevel (CoreDataGeneratedAccessors)

- (void)addMasteriesObject:(NCDBCertMastery *)value;
- (void)removeMasteriesObject:(NCDBCertMastery *)value;
- (void)addMasteries:(NSSet<NCDBCertMastery *> *)values;
- (void)removeMasteries:(NSSet<NCDBCertMastery *> *)values;

@end

NS_ASSUME_NONNULL_END
