//
//  NCDBCertMastery.h
//  NCDatabase
//
//  Created by Артем Шиманский on 16.06.14.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class NCDBCertCertificate, NCDBCertMasteryLevel, NCDBCertSkill;

@interface NCDBCertMastery : NSManagedObject

@property (nonatomic, retain) NCDBCertCertificate *certificate;
@property (nonatomic, retain) NCDBCertMasteryLevel *level;
@property (nonatomic, retain) NSSet *skills;
@end

@interface NCDBCertMastery (CoreDataGeneratedAccessors)

- (void)addSkillsObject:(NCDBCertSkill *)value;
- (void)removeSkillsObject:(NCDBCertSkill *)value;
- (void)addSkills:(NSSet *)values;
- (void)removeSkills:(NSSet *)values;

@end
