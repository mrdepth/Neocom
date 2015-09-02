//
//  NCDatabase.m
//  Neocom
//
//  Created by Артем Шиманский on 09.06.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCDatabase.h"


@implementation NCDatabase

//@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;
//@synthesize backgroundManagedObjectContext = _backgroundManagedObjectContext;

+ (id) sharedDatabase {
	@synchronized(self) {
		static NCDatabase* sharedDatabase = nil;
		static dispatch_once_t onceToken;
		dispatch_once(&onceToken, ^{
			sharedDatabase = [NCDatabase new];
		});
		return sharedDatabase;
	}
}


#pragma mark - Core Data stack

// Returns the managed object context for the application.
// If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
/*- (NSManagedObjectContext *)managedObjectContext
{
	@synchronized(self) {
		if (_managedObjectContext != nil) {
			return _managedObjectContext;
		}
		
		NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
		if (coordinator != nil) {
			_managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
			[_managedObjectContext setPersistentStoreCoordinator:coordinator];
		}
		return _managedObjectContext;
	}
}*/

/*- (NSManagedObjectContext *)backgroundManagedObjectContext
{
	@synchronized(self) {
		if (_backgroundManagedObjectContext != nil) {
			return _backgroundManagedObjectContext;
		}
		
		NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
		if (coordinator != nil) {
			_backgroundManagedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
			[_backgroundManagedObjectContext setParentContext:self.managedObjectContext];
//			[_backgroundManagedObjectContext setPersistentStoreCoordinator:coordinator];
		}
		return _backgroundManagedObjectContext;
	}
}*/


// Returns the managed object model for the application.
// If the model doesn't already exist, it is created from the application's model.
- (NSManagedObjectModel *)managedObjectModel
{
	@synchronized(self) {
		if (_managedObjectModel != nil) {
			return _managedObjectModel;
		}
		NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"NCDatabase" withExtension:@"momd"];
		_managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
		return _managedObjectModel;
	}
}

// Returns the persistent store coordinator for the application.
// If the coordinator doesn't already exist, it is created and the application's store added to it.
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
	@synchronized(self) {
		if (_persistentStoreCoordinator != nil) {
			return _persistentStoreCoordinator;
		}
		
		NSError *error = nil;
		_persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
		if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
													   configuration:nil
																 URL:[[NSBundle mainBundle] URLForResource:@"NCDatabase" withExtension:@"sqlite"]
															 options:@{NSReadOnlyPersistentStoreOption: @(YES),
																	   NSSQLitePragmasOption:@{@"journal_mode": @"OFF"}}
															   error:&error]) {
		}
		return _persistentStoreCoordinator;
	}
}

- (NSManagedObjectContext*) createManagedObjectContext {
	return [self createManagedObjectContextWithConcurrencyType:NSPrivateQueueConcurrencyType];
}

- (NSManagedObjectContext*) createManagedObjectContextWithConcurrencyType:(NSManagedObjectContextConcurrencyType) concurrencyType {
	NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
	if (coordinator != nil) {
		NSManagedObjectContext* managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:concurrencyType];
		[managedObjectContext setPersistentStoreCoordinator:coordinator];
		return managedObjectContext;
	}
	else
		return nil;
}

@end
