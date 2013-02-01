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

@implementation EUStorage

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

+ (id) sharedStorage {
	@synchronized(self) {
		if (!sharedStorage) {
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

- (void) dealloc {
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
	NSURL* url = [[NSFileManager defaultManager] URLForUbiquityContainerIdentifier:nil];
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
												   configuration:nil
															 URL:storeURL
														 options:url ? @{NSPersistentStoreUbiquitousContentNameKey : @"EUStorage", NSPersistentStoreUbiquitousContentURLKey : url} : nil
														   error:&error]) {
		
        /*
         Replace this implementation with code to handle the error appropriately.
         
         abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
         
         Typical reasons for an error here include:
         * The persistent store is not accessible;
         * The schema for the persistent store is incompatible with current managed object model.
         Check the error message to determine what the actual problem was.
         
         
         If the persistent store is not accessible, there is typically something wrong with the file path. Often, a file URL is pointing into the application's resources directory instead of a writeable directory.
         
         If you encounter schema incompatibility errors during development, you can reduce their frequency by:
         * Simply deleting the existing store:
         [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil]
         
         * Performing automatic lightweight migration by passing the following dictionary as the options parameter:
         @{NSMigratePersistentStoresAutomaticallyOption:@YES, NSInferMappingModelAutomaticallyOption:@YES}
         
         Lightweight migration will only work for a limited set of schema changes; consult "Core Data Model Versioning and Data Migration Programming Guide" for details.
         
         */
        //NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        //abort();
		dispatch_async(dispatch_get_main_queue(), ^{
			[[UIAlertView alertViewWithError:error] show];
		});
    }
    
    return _persistentStoreCoordinator;
}

@end
