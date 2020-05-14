//
//  NCTask.m
//  Neocom
//
//  Created by Artem Shimanski on 12.12.13.
//  Copyright (c) 2013 Artem Shimanski. All rights reserved.
//

#import "NCTask.h"

@implementation NCTask

- (id) init {
	if (self = [super init]) {
		
	}
	return self;
}

- (void) main {
	self.block(self);
}

- (void) start {
	@autoreleasepool {
		if (self.completionHandler) {
			NCTask* __weak weakSelf = self;
			[self setCompletionBlock:^{
				if ([NSThread isMainThread])
					weakSelf.completionHandler(weakSelf);
				else {
					NCTask* strongSelf = weakSelf;
					dispatch_async(dispatch_get_main_queue(), ^{
						strongSelf.completionHandler(strongSelf);
					});
				}
			}];
		}
		[self.delegate taskWillStart:self];
		[super start];
		[self.delegate taskDidFinish:self];
	}
}

- (void) setProgress:(float)progress {
	_progress = progress;
	[self.delegate task:self didChangeProgress:progress];
}

@end
