//
//  NCDBCertMastery.h
//  Neocom
//
//  Created by Артем Шиманский on 18.06.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
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
