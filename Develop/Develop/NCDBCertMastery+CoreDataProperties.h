//
//  NCDBCertMastery+CoreDataProperties.h
//  Develop
//
//  Created by Artem Shimanski on 20.10.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCDBCertMastery+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface NCDBCertMastery (CoreDataProperties)

+ (NSFetchRequest<NCDBCertMastery *> *)fetchRequest;

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
