//
//  NCSkillQueueItem.h
//  Neocom
//
//  Created by Artem Shimanski on 12.11.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import <Foundation/Foundation.h>

@class NCSkill;
@interface NCSkillQueueItem : NSObject
@property (nonatomic, assign) NCSkill* skill;
@property (nonatomic, assign) int32_t targetLevel;
@end
