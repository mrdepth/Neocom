//
//  NCSkillPlan.h
//  Neocom
//
//  Created by Artem Shimanski on 17.12.13.
//  Copyright (c) 2013 Artem Shimanski. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "EVEDBAPI.h"

@class NCAccount;
@interface NCSkillPlan : NSManagedObject

@property (nonatomic, retain) NSString * attributes;
@property (nonatomic) int32_t characterID;
@property (nonatomic, retain) NSString * skillPlanName;
@property (nonatomic, retain) NSString * skillPlanSkills;

@property (nonatomic, copy) NSArray* skills;
@property (nonatomic, readonly, assign) NSTimeInterval trainingTime;

+ (instancetype) temporarySkillPlanWithAccount:(NCAccount*) account;
- (void) addRequiredSkillsForType:(EVEDBInvType*) type;
- (void) addSkill:(EVEDBInvType*) skill withLevel:(NSInteger) level;

@end
