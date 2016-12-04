//
//  NCGate.m
//  Neocom
//
//  Created by Artem Shimanski on 20.11.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCGate.h"

@interface NCGate()
@property (nonatomic, copy) void (^block)();
@property (nonatomic, assign, getter=isExecuting) BOOL executing;
@property (nonatomic, strong) dispatch_queue_t dispatchQueue;
@end

@implementation NCGate

- (id) init {
	if (self = [super init]) {
		self.dispatchQueue = dispatch_queue_create(NULL, DISPATCH_QUEUE_SERIAL);
	}
	return self;
}

- (void) performBlock:(void(^)()) block {
	@synchronized (self) {
		if (self.executing) {
			self.block = block;
		}
		else {
			self.executing = YES;
			self.block = nil;
			dispatch_async(self.dispatchQueue, ^{
				@autoreleasepool {
					block();
					dispatch_async(dispatch_get_main_queue(), ^{
						@synchronized (self) {
							self.executing = NO;
							if (self.block)
								[self performBlock:self.block];
						}
					});
				}
			});
		}
	}
}

@end
