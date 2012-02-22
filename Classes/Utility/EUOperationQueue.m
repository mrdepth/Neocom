//
//  EUOperationQueue.m
//  EVEUniverse
//
//  Created by Shimanski on 8/17/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "EUOperationQueue.h"
#import "Globals.h"
#import "NSInvocation+Variadic.h"


@implementation EUOperationQueue

- (id) init {
	if (self = [super init]) {
		[self addObserver:self forKeyPath:@"operationCount" options: NSKeyValueObservingOptionNew |  NSKeyValueObservingOptionOld context:nil];
	}
	return self;
}

- (void) dealloc {
	[self removeObserver:self forKeyPath:@"operationCount"];
	[super dealloc];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	NSUInteger oldValue = [[change valueForKey:NSKeyValueChangeOldKey] unsignedIntegerValue];
	NSUInteger newValue = [[change valueForKey:NSKeyValueChangeNewKey] unsignedIntegerValue];
	if (oldValue == newValue)
		return;
	if (oldValue == 0 && newValue > 0) {
		BOOL value = YES;
		NSInvocation *invocation = [NSInvocation invocationWithTarget:[Globals appDelegate] selector:@selector(setLoading:) argumentPointers:&value];
		[invocation performSelectorOnMainThread:@selector(invoke) withObject:nil waitUntilDone:NO];
	}
	else if (oldValue > 0 && newValue == 0) {
		BOOL value = NO;
		NSInvocation *invocation = [NSInvocation invocationWithTarget:[Globals appDelegate] selector:@selector(setLoading:) argumentPointers:&value];
		[invocation performSelectorOnMainThread:@selector(invoke) withObject:nil waitUntilDone:NO];
	}
}

- (void) addOperation:(NSOperation*) operation {
	if ([operation isKindOfClass:[EUSingleBlockOperation class]]) {
		for (NSOperation *item in [self operations]) {
			if ([item isKindOfClass:[EUSingleBlockOperation class]]) {
				EUSingleBlockOperation *a = (EUSingleBlockOperation*) operation;
				EUSingleBlockOperation *b = (EUSingleBlockOperation*) item;
				if ([a.identifier isEqualToString:b.identifier]) {
					[a addDependency:b];
					[b cancel];
				}
			}
		}
	}
	[super addOperation:operation];
}

+ (EUOperationQueue*) sharedQueue {
	return [[Globals appDelegate] sharedQueue];
}

@end
