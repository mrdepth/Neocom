//
//  NCDBCertMastery.h
//  Neocom
//
//  Created by Артем Шиманский on 13.06.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
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
