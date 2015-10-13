//
//  NCDatabase.m
//  Neocom
//
//  Created by Артем Шиманский on 09.06.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCDatabase.h"
#import "NCStorage.h"

@interface NCDatabaseStore : NSIncrementalStore
@property (nonatomic, strong) NSPersistentStoreCoordinator* pc;
@property (nonatomic, strong, readonly) NSIncrementalStore* persistentStore;
@end

@implementation NCDatabaseStore

- (NSPersistentStore*) persistentStore {
	return [self.pc.persistentStores lastObject];
}

- (NSString*) type {
	return @"MyClass";
}

- (id) initWithPersistentStoreCoordinator:(NSPersistentStoreCoordinator *)root configurationName:(NSString *)name URL:(NSURL *)url options:(NSDictionary *)options {
	if (self = [super initWithPersistentStoreCoordinator:root configurationName:name URL:url options:options]) {
		self.pc = [[NCDatabase sharedDatabase] persistentStoreCoordinator];
	}
	return self;
}

- (BOOL) loadMetadata:(NSError * _Nullable __autoreleasing *)error {
	return [self.persistentStore loadMetadata:error];
}

- (NSDictionary*) metadata {
	NSMutableDictionary* metadata = [[self.persistentStore metadata] mutableCopy];
	metadata[NSStoreTypeKey] = @"MyClass";
	return @{NSStoreTypeKey:@"MyClass", NSStoreUUIDKey:metadata[NSStoreUUIDKey]};
}

- (nullable id)executeRequest:(NSPersistentStoreRequest *)request withContext:(nullable NSManagedObjectContext*)context error:(NSError **)error {
	return [self.pc executeRequest:request withContext:context error:error];
}

- (nullable NSIncrementalStoreNode *)newValuesForObjectWithID:(NSManagedObjectID*)objectID withContext:(NSManagedObjectContext*)context error:(NSError**)error {
	return [self.persistentStore newValuesForObjectWithID:objectID withContext:context error:error];
}

- (nullable id)newValueForRelationship:(NSRelationshipDescription*)relationship forObjectWithID:(NSManagedObjectID*)objectID withContext:(nullable NSManagedObjectContext *)context error:(NSError **)error {
	return [self.persistentStore newValueForRelationship:relationship forObjectWithID:objectID withContext:context error:error];
}


- (nullable NSArray<NSManagedObjectID *> *)obtainPermanentIDsForObjects:(NSArray<NSManagedObject *> *)array error:(NSError **)error {
	return [self.persistentStore obtainPermanentIDsForObjects:array error:error];
}

//- (NSManagedObjectID *)newObjectIDForEntity:(NSEntityDescription *)entity referenceObject:(id)data {
//	return [self.persistentStore newObjectIDForEntity:entity referenceObject:data];
//}

//- (id)referenceObjectForObjectID:(NSManagedObjectID *)objectID {
//	return [self.persistentStore referenceObjectForObjectID:objectID];
//}



@end


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
	static NSPersistentStoreCoordinator* pc;
	if (!pc) {
		NSManagedObjectModel* model1 = self.managedObjectModel;
		NSManagedObjectModel* model2 = [[NCStorage sharedStorage] managedObjectModel];
		pc = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[NSManagedObjectModel modelByMergingModels:@[model2, model1]]];
		[NSPersistentStoreCoordinator registerStoreClass:[NCDatabaseStore class] forStoreType:@"MyClass"];
		NSError* error = nil;
		id ps = [pc addPersistentStoreWithType:@"MyClass" configuration:@"NCDatabase" URL:[[NSBundle mainBundle] URLForResource:@"NCDatabase" withExtension:@"sqlite"] options:@{NSReadOnlyPersistentStoreOption: @(YES),
																																										 NSSQLitePragmasOption:@{@"journal_mode": @"OFF"},
																																														NSIgnorePersistentStoreVersioningOption:@(YES)} error:&error];
		NSLog(@"%@", error);
	}

	NSManagedObjectContext* managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:concurrencyType];
	[managedObjectContext setPersistentStoreCoordinator:pc];
	return managedObjectContext;
	
/*	NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
	if (coordinator != nil) {
		NSManagedObjectContext* managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:concurrencyType];
		[managedObjectContext setPersistentStoreCoordinator:coordinator];
		return managedObjectContext;
	}
	else
		return nil;*/
}

@end
