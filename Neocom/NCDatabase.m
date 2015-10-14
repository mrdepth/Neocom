//
//  NCDatabase.m
//  Neocom
//
//  Created by Артем Шиманский on 09.06.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCDatabase.h"
#import "NCStorage.h"

/*@interface NCPersistentStore : NSIncrementalStore
@property (nonatomic, strong) NSPersistentStoreCoordinator* databasePersistentStoreCoordinator;
@property (nonatomic, strong) NSIncrementalStore* databaseStore;
@property (nonatomic, strong) NSPersistentStoreCoordinator* storagePersistentStoreCoordinator;
@property (nonatomic, strong) NSIncrementalStore* storageStore;
@property (nonatomic, strong) NSManagedObjectModel* managedObjectModel;
@end

@implementation NCPersistentStore

- (id) initWithPersistentStoreCoordinator:(NSPersistentStoreCoordinator *)root configurationName:(NSString *)name URL:(NSURL *)url options:(NSDictionary *)options {
	if (self = [super initWithPersistentStoreCoordinator:root configurationName:name URL:url options:options]) {
		NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"NCDatabase" withExtension:@"momd"];
		NSManagedObjectModel* model = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
		self.pc = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model];
		self.store = [self.pc addPersistentStoreWithType:NSSQLiteStoreType
													   configuration:nil
																 URL:[[NSBundle mainBundle] URLForResource:@"NCDatabase" withExtension:@"sqlite"]
															 options:@{NSReadOnlyPersistentStoreOption: @(YES),
																	   NSSQLitePragmasOption:@{@"journal_mode": @"OFF"}}
												   error:nil];
	}
	return self;
}

- (nullable id)executeRequest:(NSPersistentStoreRequest *)request withContext:(NSManagedObjectContext *)context error:(NSError**)error {
	id res = [self.store executeRequest:request withContext:context error:error];
	return res;
}

- (BOOL) respondsToSelector:(SEL)aSelector {
	return [self.store respondsToSelector:aSelector];
}

- (NSMethodSignature*) methodSignatureForSelector:(SEL)sel {
	return [self.store methodSignatureForSelector:sel];
}

- (void) forwardInvocation:(NSInvocation *)invocation {
	NSLog(@"%@", NSStringFromSelector(invocation.selector));
	[invocation invokeWithTarget:self.store];
}

- (NSString*) type {
	return @"MyClass";
}

- (BOOL) loadMetadata:(NSError * _Nullable __autoreleasing *)error {
	return [self.store loadMetadata:error];
}

- (NSDictionary*) metadata {
	NSMutableDictionary* dic = [self.store.metadata mutableCopy];
	dic[NSStoreTypeKey] = @"MyClass";
	dic[NSStoreModelVersionHashesKey] = self.persistentStoreCoordinator.managedObjectModel.entityVersionHashesByName;
	return dic;
	//return @{NSStoreTypeKey:@"MyClass",NSStoreUUIDKey:dic[NSStoreUUIDKey]};
}

- (nullable NSIncrementalStoreNode *)newValuesForObjectWithID:(NSManagedObjectID*)objectID withContext:(NSManagedObjectContext*)context error:(NSError**)error {
	objectID = [self.pc managedObjectIDForURIRepresentation:objectID.URIRepresentation];
	return [self.store newValuesForObjectWithID:objectID withContext:context error:error];
}

- (nullable id)newValueForRelationship:(NSRelationshipDescription*)relationship forObjectWithID:(NSManagedObjectID*)objectID withContext:(nullable NSManagedObjectContext *)context error:(NSError **)error {
	objectID = [self.pc managedObjectIDForURIRepresentation:objectID.URIRepresentation];
	return [self.store newValueForRelationship:relationship forObjectWithID:objectID withContext:context error:error];
}

- (id)referenceObjectForObjectID:(NSManagedObjectID *)objectID {
	return nil;
}

@end*/


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
		
		/*modelURL = [[NSBundle mainBundle] URLForResource:@"NCStorage" withExtension:@"momd"];
		NSManagedObjectModel* model2 = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
		_managedObjectModel = [NSManagedObjectModel modelByMergingModels:@[_managedObjectModel, model2]];*/
		
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
		//[NSPersistentStoreCoordinator registerStoreClass:[NCPersistentStore class] forStoreType:@"MyClass"];
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
