//
//  SkillPlan.h
//  Neocom
//
//  Created by Артем Шиманский on 10.03.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import <CoreData/CoreData.h>

@interface SkillPlan : NSManagedObject
@property (nonatomic, strong) NSString * attributes;
@property (nonatomic) int32_t characterID;
@property (nonatomic, strong) NSString * skillPlanName;
@property (nonatomic, strong) NSString * skillPlanSkills;
@end
