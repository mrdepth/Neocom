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
#import "NCTrainingQueue.h"

@class NCAccount;
@interface NCSkillPlan : NSManagedObject

@property (nonatomic, assign) BOOL active;
@property (nonatomic, retain) NSString * skillPlanName;
@property (nonatomic, retain) NSArray* skills;
@property (nonatomic, strong) NCAccount* account;

@property (nonatomic, strong) NCTrainingQueue* trainingQueue;

- (void) save;
- (void) mergeWithTrainingQueue:(NCTrainingQueue*) trainingQueue;
- (void) removeSkill:(NCSkillData*) skill;

- (void) updateSkillPoints;
- (void) reloadIfNeeded;

@end
