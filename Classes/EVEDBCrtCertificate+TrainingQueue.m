//
//  EVEDBCrtCertificate+TrainingQueue.m
//  EVEUniverse
//
//  Created by Mr. Depth on 1/25/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "EVEDBCrtCertificate+TrainingQueue.h"
#import "TrainingQueue.h"
#import <objc/runtime.h>

@implementation EVEDBCrtCertificate (TrainingQueue)

- (TrainingQueue*) trainingQueue {
	TrainingQueue* trainingQueue = objc_getAssociatedObject(self, @"trainingQueue");
	if (!trainingQueue) {
		trainingQueue = [TrainingQueue trainingQueueWithCertificate:self];
		objc_setAssociatedObject(self, @"trainingQueue", trainingQueue, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	}
	return trainingQueue;
}

@end
