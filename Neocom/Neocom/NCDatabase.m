//
//  NCDatabase.m
//  Neocom
//
//  Created by Artem Shimanski on 20.10.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCDatabase.h"
@interface NCDatabase(){
	NSManagedObjectContext* _viewContext;
	NSManagedObjectModel* _managedObjectModel;
	NSPersistentStoreCoordinator* _persistentStoreCoordinator;
}

@end

static NCDatabase* sharedDatabase;

@implementation NCDatabase

+ (instancetype) sharedDatabase {
	return sharedDatabase;
}

+ (void) setSharedDatabase:(NCDatabase *)database {
	sharedDatabase = database;
}

- (void)loadWithCompletionHandler:(void (^)(NSError* error))block {
	NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"NCDatabase" withExtension:@"momd"];
	_managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
	
	NSString* storePath = [[NSBundle mainBundle] pathForResource:@"NCDatabase" ofType:@"sqlite"];
	
	NSError *error;
	_persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
	[_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
											  configuration:nil
														URL:[NSURL fileURLWithPath:storePath]
													options:@{NSReadOnlyPersistentStoreOption:@(YES)}
													  error:&error];
	if (self.persistentStoreCoordinator) {
		_viewContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
		_viewContext.persistentStoreCoordinator = self.persistentStoreCoordinator;
		_viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy;
		block(nil);
	}
	else if (block)
		block(error ?: [NSError errorWithDomain:@"NCDatabase" code:-1 userInfo:@{NSLocalizedDescriptionKey:NSLocalizedString(@"Unable to open database", nil)}]);
}

- (void)performBackgroundTask:(void (^)(NSManagedObjectContext* managedObjectContext))block {
	NSManagedObjectContext* context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
	context.persistentStoreCoordinator = self.persistentStoreCoordinator;
	context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy;
	[context performBlock:^{
		block(context);
	}];
}

- (void)performTaskAndWait:(void (^)(NSManagedObjectContext* managedObjectContext))block {
	NSManagedObjectContext* context = [[NSManagedObjectContext alloc] initWithConcurrencyType:[NSThread isMainThread] ? NSMainQueueConcurrencyType : NSPrivateQueueConcurrencyType];
	context.persistentStoreCoordinator = self.persistentStoreCoordinator;
	context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy;
	[context performBlockAndWait:^{
		block(context);
	}];
}

#pragma mark - Private

@end
