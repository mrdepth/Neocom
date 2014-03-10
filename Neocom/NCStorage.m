//
//  NCStorage.m
//  Neocom
//
//  Created by Artem Shimanski on 25.01.13.
//
//

#import "NCStorage.h"
//#import "Globals.h"
//#import "UIAlertView+Error.h"
//#import "UIAlertView+Block.h"

static NCStorage* sharedStorage;

@interface NCStorage()

- (void) applicationDidBecomeActive:(NSNotification*) notification;

@end

@implementation NCStorage

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

+ (id) sharedStorage {
	@synchronized(self) {
		if (!sharedStorage) {
			//if ([[NSUserDefaults standardUserDefaults] valueForKey:SettingsUseCloud] == nil)
			//	return nil;
			sharedStorage = [[NCStorage alloc] init];
		}
		return sharedStorage;
	}
}

+ (void) cleanup {
	@synchronized(self) {
		sharedStorage = nil;
	}
}

- (id) init {
	if (self = [super init]) {
//		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
//		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(ubiquityIdentityDidChange:) name:NSUbiquityIdentityDidChangeNotification object:nil];
//		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didUpdateCloud:) name:NSPersistentStoreDidImportUbiquitousContentChangesNotification object:nil];
	}
	return self;
}

- (void) dealloc {
//	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
//	[[NSNotificationCenter defaultCenter] removeObserver:self name:NSUbiquityIdentityDidChangeNotification object:nil];
//	[[NSNotificationCenter defaultCenter] removeObserver:self name:NSPersistentStoreDidImportUbiquitousContentChangesNotification object:nil];
}

- (void)saveContext
{
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
	[managedObjectContext performBlockAndWait:^{
		if (managedObjectContext != nil) {
			NSError *error = nil;
			if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
				//NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
				BOOL resolved = NO;
				for (NSMergeConflict* conflict in [error.userInfo valueForKey:@"conflictList"]) {
					[managedObjectContext refreshObject:conflict.sourceObject mergeChanges:YES];
					resolved = YES;
				}
				if (resolved) {
					error = nil;
					[managedObjectContext save:&error];
				}
			}
		}
	}];
}

#pragma mark - Core Data stack

// Returns the managed object context for the application.
// If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
- (NSManagedObjectContext *)managedObjectContext
{
	@synchronized(self) {
		if (_managedObjectContext != nil) {
			return _managedObjectContext;
		}
		
		NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
		if (coordinator != nil) {
			_managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
			[_managedObjectContext setPersistentStoreCoordinator:coordinator];
			[_managedObjectContext setMergePolicy:[[NSMergePolicy alloc] initWithMergeType:NSRollbackMergePolicyType]];
		}
		return _managedObjectContext;
	}
}

// Returns the managed object model for the application.
// If the model doesn't already exist, it is created from the application's model.
- (NSManagedObjectModel *)managedObjectModel
{
	@synchronized(self) {
		if (_managedObjectModel != nil) {
			return _managedObjectModel;
		}
		NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"NCStorage" withExtension:@"momd"];
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
		
		BOOL useCloud = NO;//[[NSUserDefaults standardUserDefaults] boolForKey:SettingsUseCloud];
		NSURL* url = useCloud ? [[NSFileManager defaultManager] URLForUbiquityContainerIdentifier:nil] : nil;
		
		NSString* directory = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES)[0] stringByAppendingPathComponent:@"com.shimanski.neocom.store"];
		[[NSFileManager defaultManager] createDirectoryAtPath:directory withIntermediateDirectories:YES attributes:nil error:nil];
		
		NSURL *storeURL = [NSURL fileURLWithPath:[directory stringByAppendingPathComponent:url ? @"cloudStore.sqlite" : @"fallbackStore.sqlite"]];
		
		NSError *error = nil;
		_persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
		NSDictionary* options = url ? @{NSPersistentStoreUbiquitousContentNameKey : @"NCStorage",
								  NSPersistentStoreUbiquitousContentURLKey : url,
								  NSInferMappingModelAutomaticallyOption : @(YES),
								  NSMigratePersistentStoresAutomaticallyOption : @(YES)} : nil;
		if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
													   configuration:nil
																 URL:storeURL
															 options:options
															   error:&error]) {
			dispatch_async(dispatch_get_main_queue(), ^{
//				[[UIAlertView alertViewWithError:error] show];
			});
		}
/*		id currentCloudToken = [[NSFileManager defaultManager] ubiquityIdentityToken];
		if (currentCloudToken) {
			NSData *tokenData = [NSKeyedArchiver archivedDataWithRootObject: currentCloudToken];
			[[NSUserDefaults standardUserDefaults] setObject: tokenData forKey:SettingsCloudToken];
		}*/
		
		return _persistentStoreCoordinator;
	}
}

#pragma mark - Private

- (void) applicationDidBecomeActive:(NSNotification*) notification {
//	[self reconnectStore];
/*	if (_persistentStoreCoordinator) {
		NSURL *storeURL = [NSURL fileURLWithPath:[[Globals documentsDirectory] stringByAppendingPathComponent:@"eustorage.sqlite"]];
		NSPersistentStore* persistentStore = [_persistentStoreCoordinator persistentStoreForURL:storeURL];
		if (persistentStore) {
			BOOL useCloud = [[NSUserDefaults standardUserDefaults] boolForKey:SettingsUseCloud];
			NSString* ubiquitousContentName = [[persistentStore options] valueForKey:@"NSPersistentStoreUbiquitousContentNameKey"];
			if ((useCloud && !ubiquitousContentName) || (!useCloud && ubiquitousContentName)) {
				[_persistentStoreCoordinator removePersistentStore:persistentStore error:nil];
				NSURL* url = useCloud ? [[NSFileManager defaultManager] URLForUbiquityContainerIdentifier:nil] : nil;
				NSError* error = nil;
				if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
															   configuration:nil
																		 URL:storeURL
																	 options:url ? @{NSPersistentStoreUbiquitousContentNameKey : @"EUStorage", NSPersistentStoreUbiquitousContentURLKey : url} : nil
																	   error:&error]) {
					[[UIAlertView alertViewWithError:error] show];
				}
			}
		}
	}*/
}

- (void) ubiquityIdentityDidChange:(NSNotification*) notification {
	[self reconnectStore];
}

- (void) didUpdateCloud:(NSNotification*) notification {
	[self.managedObjectContext performBlock:^{
		[self.managedObjectContext mergeChangesFromContextDidSaveNotification:notification];
		if ([self.managedObjectContext hasChanges])
			[self.managedObjectContext save:nil];
	}];
}

- (void) reconnectStore {
/*	id currentCloudToken = [[NSFileManager defaultManager] ubiquityIdentityToken];
	id storedCloudToken = nil;
	NSData* storedTokenData = [[NSUserDefaults standardUserDefaults] objectForKey:SettingsCloudToken];
	if (storedTokenData) {
		storedCloudToken = [NSKeyedUnarchiver unarchiveObjectWithData:storedTokenData];
	}
//	NSLog(@"Reconnect %@ %@", currentCloudToken, storedTokenData);
	
	NSURL *localStorageURL = [NSURL fileURLWithPath:[[Globals documentsDirectory] stringByAppendingPathComponent:@"localStorage.sqlite"]];
	NSURL *cloudStorageURL = [NSURL fileURLWithPath:[[Globals documentsDirectory] stringByAppendingPathComponent:@"cloudStorage.sqlite"]];
	if (!currentCloudToken && storedCloudToken) {
		[[NSUserDefaults standardUserDefaults] setValue:nil forKey:SettingsCloudToken];
		NSPersistentStore* persistentStore = [self.persistentStoreCoordinator persistentStoreForURL:cloudStorageURL];
		if (persistentStore) {
			NSError* error = nil;
			[self.persistentStoreCoordinator removePersistentStore:persistentStore error:nil];
			if (![self.persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
															   configuration:nil
																		 URL:localStorageURL
																	 options:nil
																	   error:&error]) {
				[[UIAlertView alertViewWithError:error] show];
			}
		}
	}
	else {
		if (!storedCloudToken || ![storedCloudToken isEqual:currentCloudToken]) {
			void (^migrateToCloud)() = ^() {
				__block EUOperation* operation = [EUOperation operationWithIdentifier:@"EUStorage+migrate" name:NSLocalizedString(@"Initializing storage.", nil)];
				[operation addExecutionBlock:^{
					@autoreleasepool {
						@synchronized(self) {
							BOOL useCloud = [[NSUserDefaults standardUserDefaults] boolForKey:SettingsUseCloud];
							NSURL* url = useCloud ? [[NSFileManager defaultManager] URLForUbiquityContainerIdentifier:nil] : nil;
							operation.progress = 0.5;
							if (useCloud && url) {
								NSPersistentStore* persistentStore = [self.persistentStoreCoordinator persistentStoreForURL:localStorageURL];
								NSError* error = nil;
								//[self.persistentStoreCoordinator removePersistentStore:persistentStore error:nil];
								NSDictionary* options = url ? @{NSPersistentStoreUbiquitousContentNameKey : @"EUStorage",
										NSPersistentStoreUbiquitousContentURLKey : url,
										NSInferMappingModelAutomaticallyOption : @(YES),
										NSMigratePersistentStoresAutomaticallyOption : @(YES)} : nil;
								if (![self.persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
																				   configuration:nil
																							 URL:cloudStorageURL
																						 options:options
																						   error:&error]) {
									[[UIAlertView alertViewWithError:error] show];
								}
								operation.progress = 0.8;
								[self.persistentStoreCoordinator removePersistentStore:persistentStore error:nil];
								
								NSData *tokenData = [NSKeyedArchiver archivedDataWithRootObject: currentCloudToken];
								[[NSUserDefaults standardUserDefaults] setObject: tokenData forKey:SettingsCloudToken];
							}
						}
					}
				}];
				
				[[EUOperationQueue sharedQueue] addOperation:operation];
			};
			
			if ([[NSUserDefaults standardUserDefaults] valueForKey:SettingsUseCloud] == nil) {
				[[UIAlertView alertViewWithTitle:NSLocalizedString(@"Choose Storage Option", nil)
										 message:NSLocalizedString(@"Should documents be stored in iCloud and available on all your devices?", nil)
							   cancelButtonTitle:NSLocalizedString(@"Local Only", nil)
							   otherButtonTitles:@[NSLocalizedString(@"iCloud", nil)]
								 completionBlock:^(UIAlertView *alertView, NSInteger selectedButtonIndex) {
									 [[NSUserDefaults standardUserDefaults] setBool:selectedButtonIndex != alertView.cancelButtonIndex
																			 forKey:SettingsUseCloud];
									 dispatch_async (dispatch_get_global_queue (DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), migrateToCloud);
								 } cancelBlock:nil] show];
			}
			else
				dispatch_async (dispatch_get_global_queue (DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), migrateToCloud);
		}
	}*/
}

@end
