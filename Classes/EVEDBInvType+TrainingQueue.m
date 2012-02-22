//
//  EVEDBInvType+TrainingQueue.m
//  EVEUniverse
//
//  Created by Mr. Depth on 1/25/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "EVEDBInvType+TrainingQueue.h"
#import "TrainingQueue.h"
#import <objc/runtime.h>

@implementation EVEDBInvType (TrainingQueue)

- (TrainingQueue*) trainingQueue {
	TrainingQueue* trainingQueue = objc_getAssociatedObject(self, @"trainingQueue");
	if (!trainingQueue) {
		trainingQueue = [TrainingQueue trainingQueueWithType:self];
		objc_setAssociatedObject(self, @"trainingQueue", trainingQueue, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	}
	return trainingQueue;
}

@end
