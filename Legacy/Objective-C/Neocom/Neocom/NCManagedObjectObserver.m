//
//  NCManagedObjectObserver.m
//  Neocom
//
//  Created by Artem Shimanski on 21.11.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCManagedObjectObserver.h"

@interface NCManagedObjectObserver()
@property (nonatomic, strong) NSMutableSet<NSManagedObjectID*>* objectIDs;
@property (nonatomic, copy) void(^handler)(NSSet<NSManagedObjectID*>* updated, NSSet<NSManagedObjectID*>* deleted);

@end

@implementation NCManagedObjectObserver

+ (instancetype) observerWithHandler:(void(^)(NSSet<NSManagedObjectID*>* updated, NSSet<NSManagedObjectID*>* deleted)) block {
	return [[self alloc] initWithHandler:block];
}


+ (instancetype) observerWithObjectID:(NSManagedObjectID*) objectID handler:(void(^)(NSSet<NSManagedObjectID*>* updated, NSSet<NSManagedObjectID*>* deleted)) block {
	if (!objectID)
		return nil;
	return [[self alloc] initWithObjectID:objectID handler:block];
}

- (instancetype) init {
	if (self = [super init]) {
		self.objectIDs = [NSMutableSet new];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didSave:) name:NSManagedObjectContextDidSaveNotification object:nil];
	}
	return self;
}

- (instancetype) initWithHandler:(void(^)(NSSet<NSManagedObjectID*>* updated, NSSet<NSManagedObjectID*>* deleted)) block {
	if (self = [self init]) {
		self.handler = block;
	}
	return self;
}

- (instancetype) initWithObjectID:(NSManagedObjectID*) objectID handler:(void(^)(NSSet<NSManagedObjectID*>* updated, NSSet<NSManagedObjectID*>* deleted)) block {
	if (!objectID)
		return nil;
	if (self = [self init]) {
		[self addObjectID:objectID];
		self.handler = block;
	}
	return self;
}

- (void) addObjectID:(NSManagedObjectID*) objectID {
	[self.objectIDs addObject:objectID];
}

- (void) removeObjectID:(NSManagedObjectID*) objectID {
	[self.objectIDs removeObject:objectID];
}

- (void) dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void) didSave:(NSNotification*) notification {
	NSMutableSet* updated = [notification.userInfo[NSUpdatedObjectsKey] mutableCopy];
	NSMutableSet* deleted = [notification.userInfo[NSDeletedObjectsKey] mutableCopy];
	
	[updated intersectSet:self.objectIDs];
	[deleted intersectSet:self.objectIDs];
	if (updated.count > 0 || deleted.count > 0)
		dispatch_async(dispatch_get_main_queue(), ^{
			self.handler(updated, deleted);
		});
	/*if ([[notification.userInfo[NSUpdatedObjectsKey] valueForKey:@"objectID"] containsObject:self.objectID])
		dispatch_async(dispatch_get_main_queue(), ^{
			self.block(NCManagedObjectObserverActionUpdate);
		});
	else if ([[notification.userInfo[NSDeletedObjectsKey] valueForKey:@"objectID"] containsObject:self.objectID])
		dispatch_async(dispatch_get_main_queue(), ^{
			self.block(NCManagedObjectObserverActionDelete);
		});*/
}

@end
