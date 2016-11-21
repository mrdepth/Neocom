//
//  NCManagedObjectObserver.m
//  Neocom
//
//  Created by Artem Shimanski on 21.11.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCManagedObjectObserver.h"

@interface NCManagedObjectObserver()
@property (nonatomic, strong) NSManagedObjectID* objectID;
@property (nonatomic, copy) void(^block)(NCManagedObjectObserverAction action);

@end

@implementation NCManagedObjectObserver

+ (instancetype) observerWithObjectID:(NSManagedObjectID*) objectID block:(void(^)(NCManagedObjectObserverAction action)) block {
	if (!objectID)
		return nil;
	return [[self alloc] initWithObjectID:objectID block:block];
}
- (instancetype) initWithObjectID:(NSManagedObjectID*) objectID block:(void(^)(NCManagedObjectObserverAction action)) block {
	if (!objectID)
		return nil;
	if (self = [super init]) {
		self.objectID = objectID;
		self.block = block;
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didSave:) name:NSManagedObjectContextDidSaveNotification object:nil];
	}
	return self;
}

- (void) dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void) didSave:(NSNotification*) notification {
	if ([[notification.userInfo[NSUpdatedObjectsKey] valueForKey:@"objectID"] containsObject:self.objectID])
		dispatch_async(dispatch_get_main_queue(), ^{
			self.block(NCManagedObjectObserverActionUpdate);
		});
	else if ([[notification.userInfo[NSDeletedObjectsKey] valueForKey:@"objectID"] containsObject:self.objectID])
		dispatch_async(dispatch_get_main_queue(), ^{
			self.block(NCManagedObjectObserverActionDelete);
		});
}

@end
