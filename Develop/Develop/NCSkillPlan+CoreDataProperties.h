//
//  NCSkillPlan+CoreDataProperties.h
//  Develop
//
//  Created by Artem Shimanski on 18.10.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCSkillPlan+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface NCSkillPlan (CoreDataProperties)

+ (NSFetchRequest<NCSkillPlan *> *)fetchRequest;

@property (nonatomic) BOOL active;
@property (nullable, nonatomic, copy) NSString *name;
@property (nullable, nonatomic, retain) NSObject *skills;
@property (nullable, nonatomic, retain) NCAccount *account;

@end

NS_ASSUME_NONNULL_END
