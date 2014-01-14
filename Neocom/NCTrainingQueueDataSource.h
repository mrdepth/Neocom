//
//  NCTrainingQueueDataSource.h
//  Neocom
//
//  Created by Артем Шиманский on 14.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCSkillsDataSource.h"

@class EVESkillQueue;
@interface NCTrainingQueueDataSource : NCSkillsDataSource
@property (nonatomic, strong) EVESkillQueue* skillQueue;

@end
