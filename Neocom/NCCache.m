//
//  NCCache.m
//  Neocom
//
//  Created by Artem Shimanski on 12.12.13.
//  Copyright (c) 2013 Artem Shimanski. All rights reserved.
//

#import "NCCache.h"

@interface NCCache()
//@property (readwrite, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readwrite, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readwrite, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

+ (NSString*) cacheDirectory;

@end

@implementation NCCache

+ (id) sharedCache {
	static NCCache* sharedCache;
	if (!sharedCache) {
		static dispatch_once_t onceToken;
		dispatch_once(&onceToken, ^{
			sharedCache = [NCCache new];
		});
	}
	return sharedCache;
}

- (id) init {
	if (self = [super init]) {
	}
	return self;
}

/*- (void)saveContext
{
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
	NSError* error;
	if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
	}
}*/

- (void) clear {
	NSManagedObjectContext* managedObjectContext = [self createManagedObjectContext];
	[managedObjectContext performBlock:^{
		NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Record"];
		
		NSArray *fetchedObjects = [managedObjectContext executeFetchRequest:fetchRequest error:nil];
		for (NCCacheRecord* record in fetchedObjects) {
			record.expireDate = [NSDate distantPast];
			record.date = [NSDate distantPast];
			record.data.data = nil;
		}
		[managedObjectContext save:nil];
	}];
}

- (void) clearInvalidData {
	NSManagedObjectContext* managedObjectContext = [self createManagedObjectContext];
	[managedObjectContext performBlockAndWait:^{
		@try {
			NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
			NSEntityDescription *entity = [NSEntityDescription entityForName:@"Record" inManagedObjectContext:managedObjectContext];
			[fetchRequest setEntity:entity];
			fetchRequest.predicate = [NSPredicate predicateWithFormat:@"expireDate <= %@", [NSDate dateWithTimeIntervalSinceNow:-3600 * 24 * 7]];
			
			NSArray *fetchedObjects = [managedObjectContext executeFetchRequest:fetchRequest error:nil];
			for (NCCacheRecord* record in fetchedObjects) {
				if ([record isFault])
					[managedObjectContext deleteObject:record];
				else
					record.data.data = nil;
			}
			[managedObjectContext save:nil];
		}
		@catch (NSException *exception) {
			NSString* cacheDirectory = [NCCache cacheDirectory];
			NSFileManager* fileManager = [NSFileManager defaultManager];

			for (NSString* fileName in [fileManager contentsOfDirectoryAtPath:cacheDirectory error:nil]) {
				[fileManager removeItemAtPath:[cacheDirectory stringByAppendingPathComponent:fileName] error:nil];
			}
			@throw;
		}
		@finally {
		}
	}];
}


- (NSManagedObjectContext*) createManagedObjectContext {
	NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
	if (coordinator != nil) {
		NSManagedObjectContext* managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
		[managedObjectContext setPersistentStoreCoordinator:coordinator];
		[managedObjectContext setMergePolicy:[[NSMergePolicy alloc] initWithMergeType:NSRollbackMergePolicyType]];
		return managedObjectContext;
	}
	else
		return nil;
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

// Returns the managed object model for the application.
// If the model doesn't already exist, it is created from the application's model.
- (NSManagedObjectModel *)managedObjectModel
{
	@synchronized(self) {
		if (_managedObjectModel != nil) {
			return _managedObjectModel;
		}
		NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"NCCache" withExtension:@"momd"];
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
		
		NSString* cacheDirectory = [NCCache cacheDirectory];
		[[NSFileManager defaultManager] createDirectoryAtPath:cacheDirectory withIntermediateDirectories:YES attributes:nil error:nil];
		NSString* storePath = [cacheDirectory stringByAppendingPathComponent:@"store.sqlite"];
		
		NSError *error = nil;
		_persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
		for (int i = 0; i < 2; i++) {
			if ([_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
														   configuration:nil
																	 URL:[NSURL fileURLWithPath:storePath]
																 options:nil
																   error:&error]) {
				break;
			}
			else
				[[NSFileManager defaultManager] removeItemAtPath:storePath error:nil];
		}
		return _persistentStoreCoordinator;
	}
}

#pragma mark - Private

+ (NSString*) cacheDirectory {
	return [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)[0] stringByAppendingPathComponent:@"com.shimanski.eveuniverse.NCCache"];
}

@end
