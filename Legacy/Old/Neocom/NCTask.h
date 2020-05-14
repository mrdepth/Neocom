//
//  NCTask.h
//  Neocom
//
//  Created by Artem Shimanski on 12.12.13.
//  Copyright (c) 2013 Artem Shimanski. All rights reserved.
//

#import <Foundation/Foundation.h>

@class NCTask;
@protocol NCTaskDelegate<NSObject>
- (void) taskWillStart:(NCTask*) task;
- (void) taskDidFinish:(NCTask*) task;
- (void) task:(NCTask*) task didChangeProgress:(float) progress;

@end

@interface NCTask : NSOperation
@property (nonatomic, copy) void (^block)(NCTask* task);
@property (nonatomic, copy) void (^completionHandler)(NCTask* task);
@property (nonatomic, weak) id<NCTaskDelegate> delegate;
@property (nonatomic, assign) float progress;
@property (nonatomic, copy) NSString* title;
@property (nonatomic, copy) NSString* identifier;
@end
