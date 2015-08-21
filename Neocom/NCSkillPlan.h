//
//  NCSkillPlan.h
//  Neocom
//
//  Created by Artem Shimanski on 17.12.13.
//  Copyright (c) 2013 Artem Shimanski. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "NCTrainingQueue.h"

@class NCAccount;
@interface NCSkillPlan : NSManagedObject

@property (nonatomic, assign) BOOL active;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSArray* skills;
@property (nonatomic, strong) NCAccount* account;

- (void) save;
- (void) mergeWithTrainingQueue:(NCTrainingQueue*) trainingQueue completionBlock:(void(^)(NCTrainingQueue* trainingQueue)) completionBlock;
- (void) clear;

- (void) loadTrainingQueueWithCompletionBlock:(void(^)(NCTrainingQueue* trainingQueue)) completionBlock;

@end
