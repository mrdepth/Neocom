//
//  NCDBCertMastery+CoreDataProperties.h
//  NCDatabase
//
//  Created by Artem Shimanski on 29.11.15.
//
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "NCDBCertMastery.h"

NS_ASSUME_NONNULL_BEGIN

@interface NCDBCertMastery (CoreDataProperties)

@property (nullable, nonatomic, retain) NCDBCertCertificate *certificate;
@property (nullable, nonatomic, retain) NCDBCertMasteryLevel *level;
@property (nullable, nonatomic, retain) NSSet<NCDBCertSkill *> *skills;

@end

@interface NCDBCertMastery (CoreDataGeneratedAccessors)

- (void)addSkillsObject:(NCDBCertSkill *)value;
- (void)removeSkillsObject:(NCDBCertSkill *)value;
- (void)addSkills:(NSSet<NCDBCertSkill *> *)values;
- (void)removeSkills:(NSSet<NCDBCertSkill *> *)values;

@end

NS_ASSUME_NONNULL_END
