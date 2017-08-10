//
//  NCDispatchGroup.m
//  Neocom
//
//  Created by Artem Shimanski on 17.11.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCDispatchGroup.h"

@interface NCDispatchGroup()
@property (nonatomic, strong) NSMutableIndexSet* set;
@property (strong, nonatomic) dispatch_group_t dispatchGroup;
@property (nonatomic, assign) NSInteger counter;

@end

@implementation NCDispatchGroup

- (id) init {
	if (self = [super init]) {
		self.counter = 0;
		self.dispatchGroup = dispatch_group_create();
		self.set = [NSMutableIndexSet new];
	}
	return self;
}

- (id) enter {
	NSInteger i = 0;
	@synchronized (self) {
		i = ++self.counter;
		[self.set addIndex:i];
	}
	dispatch_group_enter(self.dispatchGroup);
	return @(i);
}

- (void) leave:(id) token {
	BOOL leave = NO;
	NSInteger i = [token integerValue];
	@synchronized (self) {
		if ([self.set containsIndex:i]) {
			[self.set removeIndex:i];
			leave = YES;
		}
	}
	if (leave)
		dispatch_group_leave(self.dispatchGroup);
}

- (void) notify:(void(^)()) block {
	__block id strongSelf = self;
	dispatch_group_notify(self.dispatchGroup, dispatch_get_main_queue(), ^{
		strongSelf = nil;
		block();
	});
}


@end
