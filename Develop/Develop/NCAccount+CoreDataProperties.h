//
//  NCAccount+CoreDataProperties.h
//  Develop
//
//  Created by Artem Shimanski on 18.10.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCAccount+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface NCAccount (CoreDataProperties)

+ (NSFetchRequest<NCAccount *> *)fetchRequest;

@property (nonatomic) int32_t characterID;
@property (nonatomic) int32_t order;
@property (nullable, nonatomic, copy) NSString *uuid;
@property (nullable, nonatomic, retain) NCAPIKey *apiKey;
@property (nullable, nonatomic, retain) NCMailBox *mailBox;
@property (nullable, nonatomic, retain) NSSet<NCSkillPlan *> *skillPlans;

@end

@interface NCAccount (CoreDataGeneratedAccessors)

- (void)addSkillPlansObject:(NCSkillPlan *)value;
- (void)removeSkillPlansObject:(NCSkillPlan *)value;
- (void)addSkillPlans:(NSSet<NCSkillPlan *> *)values;
- (void)removeSkillPlans:(NSSet<NCSkillPlan *> *)values;

@end

NS_ASSUME_NONNULL_END
