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
	NSMutableSet* _updates;
	NSMutableDictionary* _identifiers;
}

@end

@implementation NCFittingEngine

- (nonnull instancetype) init {
	if (self = [super init]) {
		_engine = std::make_shared<dgmpp::Engine>(std::make_shared<dgmpp::SqliteConnector>([[[NSBundle mainBundle] pathForResource:@"dgm" ofType:@"sqlite"] cStringUsingEncoding:NSUTF8StringEncoding]));
		//_operationQueue = [NSOperationQueue new];
		//_operationQueue.maxConcurrentOperationCount = 1;
		_dispatchQueue = dispatch_queue_create("NCFittingEngine", DISPATCH_QUEUE_SERIAL);
		_updates = [NSMutableSet new];
		_identifiers = [NSMutableDictionary new];
	}
	return self;
}

- (nonnull NCFittingGang*) gang {
	NCVerifyFittingContext(self);
	return (NCFittingGang*) [NCFittingItem item: _engine->getGang() withEngine:self];
}

- (nullable NCFittingArea*) area {
	NCVerifyFittingContext(self);
	return _engine->getArea() ? (NCFittingArea*) [NCFittingItem item:_engine->getArea() withEngine:self] : nil;
}

- (void) setArea:(NCFittingArea*)area {
	NCVerifyFittingContext(self);
	_engine->setArea(static_cast<dgmpp::TypeID>(area.typeID));
	[self updateWithItem:area];
}

- (void) updateWithItem:(NCFittingItem*) item {
	[_updates addObject:item];
}

- (void) performBlock:(nonnull void(^)()) block {
	dispatch_async(_dispatchQueue, ^{
		_context = [NSThread currentThread];
		block();
		_context = nil;
		if (_updates.count > 0) {
			[_updates removeAllObjects];
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
		if (_updates.count > 0) {
			[_updates removeAllObjects];
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

- (void) assignIdentifier:(nullable NSString*) identifier forItem:(nonnull NCFittingItem*) item {
	if (identifier)
		_identifiers[@(item.hash)] = identifier;
	else
		[_identifiers removeObjectForKey:@(item.hash)];
}

- (nonnull NSString*) identifierForItem:(nonnull NCFittingItem*) item {
	NSString* identifier = _identifiers[@(item.hash)];
	if (!identifier) {
		identifier = [NSUUID UUID].UUIDString;
		[self assignIdentifier:identifier forItem:item];
		return identifier;
	}
	else
		return identifier;
}


#if DEBUG
- (void) verifyContext {
	//NSAssert([NSOperationQueue currentQueue] == _operationQueue, @"Concurency assertion");
	NSAssert([NSThread currentThread] == _context, @"Concurency assertion");
}
#endif

@end
