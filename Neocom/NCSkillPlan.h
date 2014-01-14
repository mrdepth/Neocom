//
//  NCSkillPlan.h
//  Neocom
//
//  Created by Artem Shimanski on 17.12.13.
//  Copyright (c) 2013 Artem Shimanski. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface NCSkillPlan : NSManagedObject

@property (nonatomic, retain) NSString * attributes;
@property (nonatomic) int32_t characterID;
@property (nonatomic, retain) NSString * skillPlanName;
@property (nonatomic, retain) NSString * skillPlanSkills;

@property (nonatomic, strong) NSArray* skills;

@end
