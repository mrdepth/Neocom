//
//  EUOperationQueue.m
//  EUOperationQueue
//
//  Created by Artem Shimanski on 28.08.12.
//  Copyright (c) 2012 Artem Shimanski. All rights reserved.
//

#import "EUOperationQueue.h"
#import "EUOperation.h"

static EUOperationQueue* sharedQueue;

@implementation EUOperationQueue
@synthesize delegate;
@synthesize activeOperationCount;

+ (EUOperationQueue*) sharedQueue {
	@synchronized(self) {
		if (!sharedQueue)
			sharedQueue = [[EUOperationQueue alloc] init];
		return sharedQueue;
	}
}

+ (void) cleanup {
	@synchronized(self) {
#if ! __has_feature(objc_arc)
		[sharedQueue release];
#endif
		sharedQueue = nil;
	}
}

- (void) addOperation:(NSOperation*) operation {
	if ([operation isKindOfClass:[EUOperation class]]) {
		EUOperation* currentOperation = (EUOperation*) operation;
		currentOperation.delegate = self;
		if (currentOperation.identifier) {
			for (NSOperation *item in [self operations]) {
				if ([item isKindOfClass:[EUOperation class]]) {
					EUOperation *otherOperation = (EUOperation*) item;
					if ([currentOperation.identifier isEqualToString:otherOperation.identifier]) {
						[currentOperation addDependency:otherOperation];
						[otherOperation cancel];
					}
				}
			}
		}
		[super addOperation:operation];
	}
}

- (float) progress {
	NSInteger n = 0;
	float progress = 0;
	for (EUOperation* operation in [self operations]) {
		if ([operation isKindOfClass:[EUOperation class]]) {
			progress += operation.progress;
			n++;
		}
	}
	return n > 0 ? progress / n : 1;
}

#pragma mark - EUOperationDelegate

- (void) operationDidStart:(EUOperation*)operation {
	activeOperationCount++;
	if ([delegate respondsToSelector:@selector(operationQueue:didStartOperation:)]) {
		dispatch_queue_t mainQueue = dispatch_get_main_queue();
		if (mainQueue == dispatch_get_current_queue())
			[self.delegate operationQueue:self didStartOperation:operation];
		else {
			dispatch_sync(mainQueue, ^{
				[self.delegate operationQueue:self didStartOperation:operation];
			});
		}
	}
}

- (void) operation:(EUOperation*)operation didUpdateProgress:(float) progress {
	if ([delegate respondsToSelector:@selector(operationQueue:didUpdateOperation:withProgress:)]) {
		dispatch_queue_t mainQueue = dispatch_get_main_queue();
		if (mainQueue == dispatch_get_current_queue())
			[self.delegate operationQueue:self didUpdateOperation:operation withProgress:progress];
		else {
			dispatch_sync(mainQueue, ^{
				[self.delegate operationQueue:self didUpdateOperation:operation withProgress:progress];
			});
		}
	}
}

- (void) operationDidFinish:(EUOperation*)operation {
	activeOperationCount--;
	if ([delegate respondsToSelector:@selector(operationQueue:didFinishOperation:)]) {
		dispatch_queue_t mainQueue = dispatch_get_main_queue();
		if (mainQueue == dispatch_get_current_queue())
			[self.delegate operationQueue:self didFinishOperation:operation];
		else {
			dispatch_sync(mainQueue, ^{
				[self.delegate operationQueue:self didFinishOperation:operation];
			});
		}
	}
}

@end
