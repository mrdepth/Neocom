//
//  NCFittingEngine.m
//  Neocom
//
//  Created by Artem Shimanski on 04.01.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

#import "NCFittingEngine.h"
#import <Dgmpp/Dgmpp.h>
#import "NCFittingProtected.h"

NSNotificationName const NCFittingEngineDidUpdateNotification = @"NCFittingEngineDidUpdateNotification";

@interface NCFittingEngine() {
	std::shared_ptr<dgmpp::Engine> _engine;
	//NSOperationQueue* _operationQueue;
	dispatch_queue_t _dispatchQueue;
	NSThread* _context;
	BOOL _updated;
}

@end

@implementation NCFittingEngine

- (nonnull instancetype) init {
	if (self = [super init]) {
		_engine = std::make_shared<dgmpp::Engine>(std::make_shared<dgmpp::SqliteConnector>([[[NSBundle mainBundle] pathForResource:@"dgm" ofType:@"sqlite"] cStringUsingEncoding:NSUTF8StringEncoding]));
		//_operationQueue = [NSOperationQueue new];
		//_operationQueue.maxConcurrentOperationCount = 1;
		_dispatchQueue = dispatch_queue_create("NCFittingEngine", DISPATCH_QUEUE_SERIAL);
		_updated = NO;
	}
	return self;
}

- (nonnull NCFittingGang*) gang {
	NCVerifyFittingContext(self);
	return (NCFittingGang*) [NCFittingItem item: _engine->getGang() withEngine:self];
}

- (void) didUpdate {
	_updated = YES;
}

- (void) performBlock:(nonnull void(^)()) block {
	dispatch_async(_dispatchQueue, ^{
		_context = [NSThread currentThread];
		block();
		_context = nil;
		if (_updated) {
			_updated = NO;
			dispatch_async(dispatch_get_main_queue(), ^{
				[[NSNotificationCenter defaultCenter] postNotificationName:NCFittingEngineDidUpdateNotification object:self];
			});
		}
	});
	/*[_operationQueue addOperationWithBlock:^{
		block();
		if (_updated) {
			_updated = NO;
			dispatch_async(dispatch_get_main_queue(), ^{
				[[NSNotificationCenter defaultCenter] postNotificationName:NCFittingEngineDidUpdateNotification object:self];
			});
		}
	}];*/
}

- (void) performBlockAndWait:(nonnull void(^)()) block {
	dispatch_sync(_dispatchQueue, ^{
		_context = [NSThread currentThread];
		block();
		_context = nil;
		if (_updated) {
			_updated = NO;
			dispatch_async(dispatch_get_main_queue(), ^{
				[[NSNotificationCenter defaultCenter] postNotificationName:NCFittingEngineDidUpdateNotification object:self];
			});
		}
	});
	/*[_operationQueue addOperationWithBlock:^{
		block();
		if (_updated) {
			_updated = NO;
			dispatch_async(dispatch_get_main_queue(), ^{
				[[NSNotificationCenter defaultCenter] postNotificationName:NCFittingEngineDidUpdateNotification object:self];
			});
		}
	}];
	[_operationQueue waitUntilAllOperationsAreFinished];*/
}

#if DEBUG
- (void) verifyContext {
	//NSAssert([NSOperationQueue currentQueue] == _operationQueue, @"Concurency assertion");
	NSAssert([NSThread currentThread] == _context, @"Concurency assertion");
}
#endif

@end
