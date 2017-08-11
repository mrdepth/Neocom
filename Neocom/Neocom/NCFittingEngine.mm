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
	NCFittingArea* old = (NCFittingArea*) [NCFittingItem item:_engine->getArea() withEngine:self];
	area.item = _engine->setArea(static_cast<dgmpp::TypeID>(area.typeID));
	area.engine = self;
	[self updateWithItem:area ?: old];
}

- (void) updateWithItem:(nullable NCFittingItem*) item {
	if (item) {
		[_updates addObject:item];
	}
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
}

- (void) assignIdentifier:(nullable NSString*) identifier forItem:(nonnull NCFittingItem*) item {
	if (identifier)
		_identifiers[@(item.hash)] = identifier;
	else
		[_identifiers removeObjectForKey:@(item.hash)];
}

- (nullable NSString*) identifierForItem:(nonnull NCFittingItem*) item {
	return _identifiers[@(item.hash)];
	/*NSString* identifier = _identifiers[@(item.hash)];
	if (!identifier) {
		identifier = [NSUUID UUID].UUIDString;
		[self assignIdentifier:identifier forItem:item];
		return identifier;
	}
	else
		return identifier;*/
}


#if DEBUG
- (void) verifyContext {
	//NSAssert([NSOperationQueue currentQueue] == _operationQueue, @"Concurency assertion");
	NSAssert([NSThread currentThread] == _context, @"Concurency assertion");
}
#endif

- (void) setFactorReload:(BOOL)factorReload {
	_factorReload = factorReload;
	_engine->beginUpdates();
	for (NCFittingCharacter* pilot in self.gang.pilots) {
		auto ship = std::dynamic_pointer_cast<dgmpp::Ship>(pilot.ship.item);
		if (ship) {
			ship->getCapacitorSimulator()->setReload(factorReload);
		}
		for (NCFittingModule* module in pilot.ship.modules) {
			module.factorReload = factorReload;
		}
	}
	_engine->commitUpdates();
}

- (nullable NCFittingPlanet*) planet {
	NCVerifyFittingContext(self);
	return _engine->getPlanet() ? [[NCFittingPlanet alloc] initWithPlanet:_engine->getPlanet() engine:self] : nil;
}

- (void) setPlanet:(NCFittingPlanet *)planet {
	NCVerifyFittingContext(self);
	planet.planet = _engine->setPlanet(static_cast<dgmpp::TypeID>(planet.typeID));
	planet.engine = self;

}

@end
