//
//  EUOperationQueue.h
//  EUOperationQueue
//
//  Created by Artem Shimanski on 28.08.12.
//  Copyright (c) 2012 Artem Shimanski. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EUOperation.h"

@class EUOperationQueue;
@protocol EUOperationQueueDelegate <NSObject>
@optional
- (void) operationQueue:(EUOperationQueue*) operationQueue didStartOperation:(EUOperation*)operation;
- (void) operationQueue:(EUOperationQueue*) operationQueue didFinishOperation:(EUOperation*)operation;
- (void) operationQueue:(EUOperationQueue*) operationQueue didUpdateOperation:(EUOperation*)operation withProgress:(float) progress;

@end

@interface EUOperationQueue : NSOperationQueue<EUOperationDelegate>
@property (nonatomic, readonly) float progress;
@property (nonatomic, assign) id<EUOperationQueueDelegate> delegate;
@property (nonatomic, readonly) NSInteger activeOperationCount;

+ (EUOperationQueue*) sharedQueue;
+ (void) cleanup;

@end
