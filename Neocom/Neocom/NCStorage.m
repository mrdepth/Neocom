//
//  NCStorage.m
//  Neocom
//
//  Created by Artem Shimanski on 20.10.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCStorage.h"

@interface NCStorage()
@property (nonatomic, assign, readwrite) NCStorageType storageType;

@end

static NCStorage* sharedStorage;

@implementation NCStorage

+ (instancetype) sharedStorage {
	return sharedStorage;
}

+ (void) setSharedStorage:(NCStorage*) storage {
	sharedStorage = storage;
}

+ (instancetype) cloudStorage {
	return [[self alloc] initWithStorageType:NCStorageTypeCloud];
}

+ (instancetype) localStorage {
	return [[self alloc] initWithStorageType:NCStorageTypeLocal];
}


- (id) init {
	if (self = [super init]) {
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(managedObjectContextDidSave:) name:NSManagedObjectContextDidSaveNotification object:nil];
	}
	return self;
}

- (void) dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)loadWithCompletionHandler:(void (^)(NSError* error))block {
	NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"NCStorage" withExtension:@"momd"];
	_managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
	
	NSMutableDictionary* options = [NSMutableDictionary new];
	NSURL* storeURL;
	NSString* directory = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES)[0] stringByAppendingPathComponent:@"com.shimanski.neocom.store"];
	[[NSFileManager defaultManager] createDirectoryAtPath:directory withIntermediateDirectories:YES attributes:nil error:nil];
	if (self.storageType == NCStorageTypeLocal) {
		storeURL = [NSURL fileURLWithPath:[directory stringByAppendingPathComponent:@"fallbackStore.sqlite"]];
	}
	else {
		id currentCloudToken = [[NSFileManager defaultManager] ubiquityIdentityToken];
		NSURL* url = [[NSFileManager defaultManager] URLForUbiquityContainerIdentifier:nil];
		if (url) {
			storeURL = [NSURL fileURLWithPath:[directory stringByAppendingPathComponent:@"cloudStore.sqlite"]];
			
			id lastCloudToken = nil;
			NSData *tokenData = [[NSUserDefaults standardUserDefaults] valueForKey:@"CloudToken"];
			if (tokenData)
				lastCloudToken = [NSKeyedUnarchiver unarchiveObjectWithData:tokenData];
			
			if (lastCloudToken && ![lastCloudToken isEqual:currentCloudToken]) {
				[[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil];
			}
			
			tokenData = [NSKeyedArchiver archivedDataWithRootObject: currentCloudToken];
			[[NSUserDefaults standardUserDefaults] setObject: tokenData forKey:@"CloudToken"];
			[[NSUserDefaults standardUserDefaults] synchronize];
			
			options = [@{NSPersistentStoreUbiquitousContentNameKey : @"NCStorage",
						 NSPersistentStoreUbiquitousContentURLKey : url,
						 NSInferMappingModelAutomaticallyOption : @(YES),
						 NSMigratePersistentStoresAutomaticallyOption : @(YES)} mutableCopy];
		}
	}
	
	NSError *error;
	NSPersistentStoreCoordinator* persistentStoreCoordinator;
	if (storeURL) {
		persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
		for (int i = 0; i < 2; i++) {
			error = nil;
			NSPersistentStore* persistentStore = nil;
			@try {
				persistentStore = [persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
																		   configuration:@"Cloud"
																					 URL:storeURL
																				 options:options
																				   error:&error];
			}
			@catch (NSException *exception) {
			}
			@finally {
			}
			if (persistentStore)
				break;
			else {
				if (self.storageType == NCStorageTypeLocal)
					[[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil];
				else
					options[NSPersistentStoreRebuildFromUbiquitousContentOption] = @(YES);
			}
		}
	}
	else {
		error = [NSError errorWithDomain:@"NCStorage" code:-1 userInfo:@{NSLocalizedDescriptionKey:NSLocalizedString(@"Unable to create cloud store", nil)}];
	}
	
	if (error)
		persistentStoreCoordinator = nil;
	else {
		storeURL = [NSURL fileURLWithPath:[directory stringByAppendingPathComponent:@"localStore.sqlite"]];
		
		for (int n = 0; n < 2; n++) {
			error = nil;
			if ([persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
														 configuration:@"Local"
																   URL:storeURL
															   options:@{NSInferMappingModelAutomaticallyOption : @(YES),
																		 NSMigratePersistentStoresAutomaticallyOption : @(YES)}
																 error:&error])
				break;
			else
				[[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil];
		}
	}
	if (error)
		persistentStoreCoordinator = nil;
	
	if (persistentStoreCoordinator) {
		_persistentStoreCoordinator = persistentStoreCoordinator;
		_viewContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
		_viewContext.persistentStoreCoordinator = self.persistentStoreCoordinator;
		_viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy;
		block(nil);
	}
	else if (block)
		block(error ?: [NSError errorWithDomain:@"NCCache" code:-1 userInfo:@{NSLocalizedDescriptionKey:NSLocalizedString(@"Unable to create cache store", nil)}]);
}

- (void)performBackgroundTask:(void (^)(NSManagedObjectContext* managedObjectContext))block {
	NSManagedObjectContext* context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
	context.persistentStoreCoordinator = self.persistentStoreCoordinator;
	context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy;
	[context performBlock:^{
		block(context);
		NSError* error = nil;
		if ([context hasChanges])
			[context save:&error];
		if (error)
			NSLog(@"%@", error);
	}];
}

- (BOOL) isLoaded {
	return _persistentStoreCoordinator != nil;
}

#pragma mark - Private

- (id) initWithStorageType:(NCStorageType) storageType {
	if (self = [self init]) {
		self.storageType = storageType;
	}
	return self;
}

- (void) managedObjectContextDidSave:(NSNotification*) note {
	NSManagedObjectContext* context = note.object;
	if (context != _viewContext && context.persistentStoreCoordinator == _persistentStoreCoordinator) {
		[_viewContext performBlock:^{
			[_viewContext mergeChangesFromContextDidSaveNotification:note];
		}];
	}
}


@end
