//
//  EUStorage.m
//  EVEUniverse
//
//  Created by Artem Shimanski on 25.01.13.
//
//

#import "EUStorage.h"
#import "Globals.h"
#import "UIAlertView+Error.h"

static EUStorage* sharedStorage;

@interface EUStorage()

- (void) applicationDidBecomeActive:(NSNotification*) notification;

@end

@implementation EUStorage

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

+ (id) sharedStorage {
	@synchronized(self) {
		if (!sharedStorage) {
			if ([[NSUserDefaults standardUserDefaults] valueForKey:SettingsUseCloud] == nil)
				return nil;
			sharedStorage = [[EUStorage alloc] init];
		}
		return sharedStorage;
	}
}

+ (void) cleanup {
	@synchronized(self) {
		[sharedStorage release];
		sharedStorage = nil;
	}
}

- (id) init {
	if (self = [super init]) {
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
	}
	return self;
}

- (void) dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
	[_managedObjectContext release];
	[_managedObjectModel release];
	[_persistentStoreCoordinator release];
	[super dealloc];
}

- (void)saveContext
{
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
	[managedObjectContext performBlockAndWait:^{
		if (managedObjectContext != nil) {
			NSError *error = nil;
			if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
				NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
				BOOL resolved = NO;
				for (NSMergeConflict* conflict in [error.userInfo valueForKey:@"conflictList"]) {
					[managedObjectContext refreshObject:conflict.sourceObject mergeChanges:YES];
					resolved = YES;
				}
				if (resolved) {
					error = nil;
					[managedObjectContext save:&error];
					NSLog(@"%@", error);
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
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        _managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        [_managedObjectContext setPersistentStoreCoordinator:coordinator];
		[_managedObjectContext setMergePolicy:[[[NSMergePolicy alloc] initWithMergeType:NSMergeByPropertyStoreTrumpMergePolicyType] autorelease]];
		[_managedObjectContext setStalenessInterval:0];
    }
    return _managedObjectContext;
}

// Returns the managed object model for the application.
// If the model doesn't already exist, it is created from the application's model.
- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"EUStorage" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

// Returns the persistent store coordinator for the application.
// If the coordinator doesn't already exist, it is created and the application's store added to it.
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    NSURL *storeURL = [NSURL fileURLWithPath:[[Globals documentsDirectory] stringByAppendingPathComponent:@"eustorage.sqlite"]];
    
    NSError *error = nil;
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
	BOOL useCloud = [[NSUserDefaults standardUserDefaults] boolForKey:SettingsUseCloud];
	NSURL* url = useCloud ? [[NSFileManager defaultManager] URLForUbiquityContainerIdentifier:nil] : nil;
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
												   configuration:nil
															 URL:storeURL
														 options:url ? @{NSPersistentStoreUbiquitousContentNameKey : @"EUStorage", NSPersistentStoreUbiquitousContentURLKey : url} : nil
														   error:&error]) {
		dispatch_async(dispatch_get_main_queue(), ^{
			[[UIAlertView alertViewWithError:error] show];
		});
    }
    
    return _persistentStoreCoordinator;
}

#pragma mark - Private

- (void) applicationDidBecomeActive:(NSNotification*) notification {
	if (_persistentStoreCoordinator) {
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
	}
}

@end
