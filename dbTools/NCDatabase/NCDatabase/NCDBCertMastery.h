//
//  NCDBCertMastery.h
//  NCDatabase
//
//  Created by Shimanski Artem on 15.06.14.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class NCDBCertCertificate, NCDBCertMasteryLevel, NCDBCertSkill, NCDBInvType;

@interface NCDBCertMastery : NSManagedObject

@property (nonatomic, retain) NCDBCertCertificate *certificate;
@property (nonatomic, retain) NCDBCertMasteryLevel *level;
@property (nonatomic, retain) NSSet *skills;
@property (nonatomic, retain) NSSet *types;
@end

@interface NCDBCertMastery (CoreDataGeneratedAccessors)

- (void)addSkillsObject:(NCDBCertSkill *)value;
- (void)removeSkillsObject:(NCDBCertSkill *)value;
- (void)addSkills:(NSSet *)values;
- (void)removeSkills:(NSSet *)values;

- (void)addTypesObject:(NCDBInvType *)value;
- (void)removeTypesObject:(NCDBInvType *)value;
- (void)addTypes:(NSSet *)values;
- (void)removeTypes:(NSSet *)values;

@end
