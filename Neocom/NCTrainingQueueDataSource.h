//
//  NCTrainingQueueDataSource.h
//  Neocom
//
//  Created by Артем Шиманский on 14.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCSkillsDataSource.h"

@class EVESkillQueue;
@class NCSkillPlan;
@interface NCTrainingQueueDataSource : NCSkillsDataSource
@property (nonatomic, strong) EVESkillQueue* skillQueue;
@property (nonatomic, strong) NCSkillPlan* skillPlan;

@end
