//
//  NCFittingEngine.m
//  Neocom
//
//  Created by Artem Shimanski on 18.09.15.
//  Copyright © 2015 Artem Shimanski. All rights reserved.
//

#import "NCFittingEngine.h"

@interface NCFittingEngine()
//@property (nonatomic, strong) dispatch_queue_t privateQueue;

@end

@implementation NCFittingEngine
@synthesize engine = _engine;

- (id) init {
	if (self = [super init]) {
		_engine = new eufe::Engine(new eufe::SqliteConnector([[[NSBundle mainBundle] pathForResource:@"eufe" ofType:@"sqlite"] cStringUsingEncoding:NSUTF8StringEncoding]));
//		self.privateQueue = dispatch_queue_create(0, DISPATCH_QUEUE_SERIAL);
	}
	return self;
}

- (void) dealloc {
	delete _engine;
}

- (void)performBlockAndWait:(void (^)())block {
//	dispatch_sync(self.privateQueue, ^{
//		@autoreleasepool {
			eufe::Engine::ScopedLock lock(_engine);
			block();
//		}
//	});
}

- (NCDBInvType*) typeWithItem:(eufe::Item*) item {
	return nil;
}

@end
