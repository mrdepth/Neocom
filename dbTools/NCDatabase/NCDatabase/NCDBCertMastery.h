//
//  NCDBCertMastery.h
//  NCDatabase
//
//  Created by Артем Шиманский on 15.05.14.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class NCDBCertCertificate, NCDBCertMasteryLevel, NCDBCertSkill, NCDBInvType;

@interface NCDBCertMastery : NSManagedObject

@property (nonatomic, retain) NSSet *types;
@property (nonatomic, retain) NSSet *skills;
@property (nonatomic, retain) NCDBCertMasteryLevel *level;
@property (nonatomic, retain) NCDBCertCertificate *certificate;
@end

@interface NCDBCertMastery (CoreDataGeneratedAccessors)

- (void)addTypesObject:(NCDBInvType *)value;
- (void)removeTypesObject:(NCDBInvType *)value;
- (void)addTypes:(NSSet *)values;
- (void)removeTypes:(NSSet *)values;

- (void)addSkillsObject:(NCDBCertSkill *)value;
- (void)removeSkillsObject:(NCDBCertSkill *)value;
- (void)addSkills:(NSSet *)values;
- (void)removeSkills:(NSSet *)values;

@end
