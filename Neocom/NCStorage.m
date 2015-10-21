//
//  NCStorage.m
//  Neocom
//
//  Created by Artem Shimanski on 25.01.13.
//
//

#import "NCStorage.h"
#import "NCAccount.h"
#import "NCLoadout.h"
#import "NCSkillPlan.h"
#import "NCDamagePattern.h"
#import "NCImplantSet.h"
#import "NCFitCharacter.h"
#import <objc/runtime.h>
#import "NSData+MD5.h"
#import "NCMigrationManager.h"
#import "UIAlertController+Neocom.h"


@interface NCValueTransformer : NSValueTransformer

@end

@implementation NCValueTransformer

+ (void) load {
	[NSValueTransformer setValueTransformer:[self new] forName:@"NCValueTransformer"];
}

+ (BOOL)allowsReverseTransformation {
    return YES;
}


+ (Class)transformedValueClass {
    return [NSData class];
}


- (id)transformedValue:(id)value {
	@try {
		if (![value respondsToSelector:@selector(encodeWithCoder:)])
			return nil;
		else
			return [NSKeyedArchiver archivedDataWithRootObject:value];
	}
	@catch (NSException *exception) {
		return nil;
	}
}


- (id)reverseTransformedValue:(id)value {
	@try {
		return [NSKeyedUnarchiver unarchiveObjectWithData:value];
	}
	@catch (NSException *exception) {
		return nil;
	}
}

@end

static NCStorage* sharedStorage;

@interface NCStorage()
@property (nonatomic, assign, readwrite) NCStorageType storageType;
@property (nonatomic, strong) id observer;

- (void) didUpdateCloud:(NSNotification*) notification;
- (void) notifyStorageChange;

@end

@implementation NCStorage

@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

+ (instancetype) sharedStorage {
	@synchronized(self) {
		return sharedStorage.observer ? nil : sharedStorage;
	}
}

+ (void) setSharedStorage:(NCStorage*) storage {
	@synchronized(self) {
		sharedStorage = storage;
	}
}

- (void) didChange:(NSNotification*) notification {
	
}

- (void) willChange:(NSNotification*) notification {
	if (!self.observer && notification.object == self.persistentStoreCoordinator)
		self.observer = [[NSNotificationCenter defaultCenter] addObserverForName:NSPersistentStoreCoordinatorStoresDidChangeNotification
																		  object:notification.object
																		   queue:[NSOperationQueue mainQueue]
																	  usingBlock:^(NSNotification *note) {

																		  if ([notification.userInfo[NSPersistentStoreUbiquitousTransitionTypeKey] integerValue] == NSPersistentStoreUbiquitousTransitionTypeInitialImportCompleted) {
																			  if (![[NSUserDefaults standardUserDefaults] boolForKey:NCSettingsDontNeedsCloudTransfer]) {
																				  [[NSUserDefaults standardUserDefaults] setInteger:NCStorageTypeCloud forKey:NCSettingsStorageType];
																				  [[NSUserDefaults standardUserDefaults] synchronize];
																				  self.storageType = NCStorageTypeCloud;
																			  }
																		  }
																		  
																		  [[NSNotificationCenter defaultCenter] removeObserver:self.observer];

																		  self.observer = nil;
																		  [self notifyStorageChange];

																	  }];
}

- (id) init {
	if (self = [super init]) {
//		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didUpdateCloud:) name:NSPersistentStoreDidImportUbiquitousContentChangesNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willChange:) name:NSPersistentStoreCoordinatorStoresWillChangeNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didChange:) name:NSPersistentStoreCoordinatorStoresDidChangeNotification object:nil];
	}
	return self;
}

- (void) dealloc {
	if (self.observer)
		[[NSNotificationCenter defaultCenter] removeObserver:self.observer];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (id) initLocalStorage {
	if (self = [self init]) {
		self.storageType = NCStorageTypeLocal;
		NSString* directory = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES)[0] stringByAppendingPathComponent:@"com.shimanski.neocom.store"];
		[[NSFileManager defaultManager] createDirectoryAtPath:directory withIntermediateDirectories:YES attributes:nil error:nil];
		
		_persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];

		NSError *error = nil;
		NSURL *storeURL = [NSURL fileURLWithPath:[directory stringByAppendingPathComponent:@"fallbackStore.sqlite"]];
		for (int n = 0; n < 2; n++) {
			error = nil;
			if ([_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
														   configuration:@"Cloud"
																	 URL:storeURL
																options:@{NSInferMappingModelAutomaticallyOption : @(NO),
																		  NSMigratePersistentStoresAutomaticallyOption : @(NO)}
																   error:&error])
				break;
			else
				[[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil];
		}
		if (error) {
			dispatch_async(dispatch_get_main_queue(), ^{
				[[UIAlertController frontMostViewController] presentViewController:[UIAlertController alertWithError:error] animated:YES completion:nil];
			});
			return nil;
		}
		storeURL = [NSURL fileURLWithPath:[directory stringByAppendingPathComponent:@"localStore.sqlite"]];

		for (int n = 0; n < 2; n++) {
			error = nil;
			if ([_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
														  configuration:@"Local"
																	URL:storeURL
																options:@{NSInferMappingModelAutomaticallyOption : @(YES),
																		  NSMigratePersistentStoresAutomaticallyOption : @(YES)}
																  error:&error])
				break;
			else
				[[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil];
		}
		if (error) {
			dispatch_async(dispatch_get_main_queue(), ^{
				[[UIAlertController frontMostViewController] presentViewController:[UIAlertController alertWithError:error] animated:YES completion:nil];
			});
			return nil;
		}
		
		[self notifyStorageChange];
	}
	return self;
}

- (id) initCloudStorage {
	if (self = [self init]) {
		id currentCloudToken = [[NSFileManager defaultManager] ubiquityIdentityToken];

		
		NSURL* url = [[NSFileManager defaultManager] URLForUbiquityContainerIdentifier:nil];
		if (!url)
			return nil;

		NSString* directory = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES)[0] stringByAppendingPathComponent:@"com.shimanski.neocom.store"];
		[[NSFileManager defaultManager] createDirectoryAtPath:directory withIntermediateDirectories:YES attributes:nil error:nil];
		NSURL *storeURL = [NSURL fileURLWithPath:[directory stringByAppendingPathComponent:@"cloudStore.sqlite"]];

		id lastCloudToken = nil;
		NSData *tokenData = [[NSUserDefaults standardUserDefaults] valueForKey:NCSettingsCloudTokenKey];
		if (tokenData)
			lastCloudToken = [NSKeyedUnarchiver unarchiveObjectWithData:tokenData];
		
		if (lastCloudToken && ![lastCloudToken isEqual:currentCloudToken]) {
			[[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil];
		}

		tokenData = [NSKeyedArchiver archivedDataWithRootObject: currentCloudToken];
		[[NSUserDefaults standardUserDefaults] setObject: tokenData forKey:NCSettingsCloudTokenKey];
		[[NSUserDefaults standardUserDefaults] synchronize];

		NSMutableDictionary* options = [@{NSPersistentStoreUbiquitousContentNameKey : @"NCStorage",
								  NSPersistentStoreUbiquitousContentURLKey : url,
								  NSInferMappingModelAutomaticallyOption : @(YES),
								  NSMigratePersistentStoresAutomaticallyOption : @(YES)} mutableCopy];
		{
			NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"NCStorage" withExtension:@"momd"];
			NSManagedObjectModel* model = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
			//options[NSStoreModelVersionHashesKey] = [model entityVersionHashesByName];

		}
/*		if (![[NSUserDefaults standardUserDefaults] boolForKey:NCSettingsDontNeedsCloudReset]) {
			options[NSPersistentStoreRebuildFromUbiquitousContentOption] = @(YES);
			[[NSUserDefaults standardUserDefaults] setInteger:NCStorageTypeFallback forKey:NCSettingsStorageType];
			self.storageType = NCStorageTypeFallback;
			[[NSUserDefaults standardUserDefaults] setBool:YES forKey:NCSettingsDontNeedsCloudReset];
			[[NSUserDefaults standardUserDefaults] synchronize];
		}
		else
			self.storageType = [[NSUserDefaults standardUserDefaults] integerForKey:NCSettingsStorageType];*/
		self.storageType = NCStorageTypeCloud;

		
		_persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
		
		NSError *error = nil;
		
//		if ([[NSUserDefaults standardUserDefaults] boolForKey:@"NCCloudInitialization"])
//			options[NSPersistentStoreRebuildFromUbiquitousContentOption] = @(YES);
		
//		[[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"NCCloudInitialization"];
//		[[NSUserDefaults standardUserDefaults] synchronize];
		for (int n = 0; n < 2; n++) {
			error = nil;
			NSPersistentStore* persistentStore = nil;
			@try {
				persistentStore = [_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
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
				options[NSPersistentStoreRebuildFromUbiquitousContentOption] = @(YES);
			}
		}
//		[[NSUserDefaults standardUserDefaults] removeObjectForKey:@"NCCloudInitialization"];

		if (error) {
			dispatch_async(dispatch_get_main_queue(), ^{
				[[UIAlertController frontMostViewController] presentViewController:[UIAlertController alertWithError:error] animated:YES completion:nil];
			});
			return nil;
		}
		storeURL = [NSURL fileURLWithPath:[directory stringByAppendingPathComponent:@"localStore.sqlite"]];
		
		for (int n = 0; n < 2; n++) {
			error = nil;
			if ([_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
														  configuration:@"Local"
																	URL:storeURL
																options:@{NSInferMappingModelAutomaticallyOption : @(YES),
																		  NSMigratePersistentStoresAutomaticallyOption : @(YES)}
																  error:&error])
				break;
			else
				[[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil];
		}
		if (error) {
			dispatch_async(dispatch_get_main_queue(), ^{
				[[UIAlertController frontMostViewController] presentViewController:[UIAlertController alertWithError:error] animated:YES completion:nil];
			});
			return nil;
		}
		
		
		[self notifyStorageChange];
	}
	return self;
}

/*- (void)saveContext
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
}*/

- (BOOL) backupCloudData {
	NSURL* url = [[NSFileManager defaultManager] URLForUbiquityContainerIdentifier:nil];
	if (!url)
		return NO;

	NSString* directory = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES)[0] stringByAppendingPathComponent:@"com.shimanski.neocom.store"];
	NSURL *storeURL = [NSURL fileURLWithPath:[directory stringByAppendingPathComponent:@"cloudStore.sqlite"]];
	NSURL *fallbackURL = [NSURL fileURLWithPath:[directory stringByAppendingPathComponent:@"fallbackStore.sqlite"]];

	NSPersistentStoreCoordinator* persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:self.managedObjectModel];
	
	if ([persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
												 configuration:@"Cloud"
														   URL:storeURL
													   options:@{NSPersistentStoreUbiquitousContentNameKey : @"NCStorage",
																 NSPersistentStoreUbiquitousContentURLKey : url,
																 NSInferMappingModelAutomaticallyOption : @(YES),
																 NSMigratePersistentStoresAutomaticallyOption : @(YES)}
														 error:nil]) {
		NSError* error = nil;
		if ([persistentStoreCoordinator migratePersistentStore:[persistentStoreCoordinator.persistentStores lastObject]
															toURL:fallbackURL
														  options:@{NSInferMappingModelAutomaticallyOption : @(YES),
																 NSMigratePersistentStoresAutomaticallyOption : @(YES),
																 NSPersistentStoreRemoveUbiquitousMetadataOption:@(YES)}
			 
														 withType:NSSQLiteStoreType
															error:&error]) {
			[self removeDuplicatesFromPersistentStoreCoordinator:persistentStoreCoordinator];
			return YES;
		}
	}
	return NO;
}

- (BOOL) restoreCloudData {
	NSURL* url = [[NSFileManager defaultManager] URLForUbiquityContainerIdentifier:nil];
	if (!url)
		return NO;
	
	_persistentStoreCoordinator = nil;
	
	NSString* directory = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES)[0] stringByAppendingPathComponent:@"com.shimanski.neocom.store"];
	NSURL *storeURL = [NSURL fileURLWithPath:[directory stringByAppendingPathComponent:@"cloudStore.sqlite"]];
	NSURL *fallbackURL = [NSURL fileURLWithPath:[directory stringByAppendingPathComponent:@"fallbackStore.sqlite"]];
	
	NSPersistentStoreCoordinator* persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:self.managedObjectModel];
	
	if ([persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
												 configuration:@"Cloud"
														   URL:fallbackURL
													   options:@{NSInferMappingModelAutomaticallyOption : @(YES),
																 NSMigratePersistentStoresAutomaticallyOption : @(YES),
																 NSPersistentStoreRemoveUbiquitousMetadataOption:@(YES)}
														 error:nil]) {
		NSError* error = nil;
		if ([persistentStoreCoordinator migratePersistentStore:[persistentStoreCoordinator.persistentStores lastObject]
															toURL:storeURL
													   options:@{NSPersistentStoreUbiquitousContentNameKey : @"NCStorage",
																 NSPersistentStoreUbiquitousContentURLKey : url,
																 NSInferMappingModelAutomaticallyOption : @(YES),
																 NSMigratePersistentStoresAutomaticallyOption : @(YES)}
														 withType:NSSQLiteStoreType
															error:&error]) {
			[self removeDuplicatesFromPersistentStoreCoordinator:persistentStoreCoordinator];
			return YES;
		}
	}
	return NO;
}

#pragma mark - Core Data stack

- (NSManagedObjectContext*) createManagedObjectContext {
	return [self createManagedObjectContextWithConcurrencyType:NSPrivateQueueConcurrencyType];
}

- (NSManagedObjectContext*) createManagedObjectContextWithConcurrencyType:(NSManagedObjectContextConcurrencyType) concurrencyType {
	NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
	if (coordinator != nil) {
		NSManagedObjectContext* managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:concurrencyType];
		[managedObjectContext setPersistentStoreCoordinator:coordinator];
		[managedObjectContext setMergePolicy:[[NSMergePolicy alloc] initWithMergeType:NSRollbackMergePolicyType]];
		return managedObjectContext;
	}
	else
		return nil;
}

- (NSManagedObjectModel*) managedObjectModel {
	@synchronized(self) {
		if (_managedObjectModel != nil) {
			return _managedObjectModel;
		}
		NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"NCStorage" withExtension:@"momd"];
		_managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
		//modelURL = [[NSBundle mainBundle] URLForResource:@"NCDatabase" withExtension:@"momd"];
		//NSManagedObjectModel* databaseManagedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
		//_managedObjectModel = [NSManagedObjectModel modelByMergingModels:@[_managedObjectModel, databaseManagedObjectModel]];
		return _managedObjectModel;
	}
}

#pragma mark - Private

/*- (void) didUpdateCloud:(NSNotification*) notification {
	[self.managedObjectContext performBlock:^{
		[self.managedObjectContext mergeChangesFromContextDidSaveNotification:notification];
		NSError* error = nil;
		if ([self.managedObjectContext hasChanges])
			[self.managedObjectContext save:&error];
		
		if ([NSThread isMainThread]) {
			[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(notifyStorageChange) object:nil];
			[self performSelector:@selector(notifyStorageChange) withObject:nil afterDelay:1.0];
		}
		else {
			dispatch_async(dispatch_get_main_queue(), ^{
				[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(notifyStorageChange) object:nil];
				[self performSelector:@selector(notifyStorageChange) withObject:nil afterDelay:1.0];
			});
		}
	}];
}*/

- (void) notifyStorageChange {
	NCAccount* account = [NCAccount currentAccount];
	dispatch_async(dispatch_get_main_queue(), ^{
		if (account && !account.managedObjectContext)
			[NCAccount setCurrentAccount:nil];
		[[NSNotificationCenter defaultCenter] postNotificationName:NCStorageDidChangeNotification object:self userInfo:nil];
	});
}

- (void) removeDuplicatesFromPersistentStoreCoordinator:(NSPersistentStoreCoordinator*) persistentStoreCoordinator {
	NSManagedObjectContext* context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
	[context setPersistentStoreCoordinator:persistentStoreCoordinator];
	[context performBlockAndWait:^{
		NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"Account"];
		NSMutableSet* items = [NSMutableSet new];
		for (NCAccount* account in [context executeFetchRequest:request error:nil]) {
			if ([items containsObject:account.uuid]) {
				account.apiKey = nil;
				[context deleteObject:account];
			}
			else
				[items addObject:account.uuid];
		}

		request = [NSFetchRequest fetchRequestWithEntityName:@"APIKey"];
		for (NCAPIKey* apiKey in [context executeFetchRequest:request error:nil]) {
			if (apiKey.accounts.count == 0)
				[context deleteObject:apiKey];
		}

		request = [NSFetchRequest fetchRequestWithEntityName:@"Loadout"];
		items = [NSMutableSet new];
		for (NCLoadout* loadout in [context executeFetchRequest:request error:nil]) {
			NSMutableData* data = [NSMutableData new];
			NSKeyedArchiver* archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
			[archiver encodeObject:loadout.data.data forKey:@"data"];
			[archiver encodeObject:loadout.name forKey:@"name"];
			[archiver encodeInt32:loadout.typeID forKey:@"typeID"];
			[archiver finishEncoding];
			NSString* item = [data md5];
			
			if ([items containsObject:item])
				[context deleteObject:loadout];
			else
				[items addObject:item];
		}

		request = [NSFetchRequest fetchRequestWithEntityName:@"SkillPlan"];
		items = [NSMutableSet new];
		for (NCSkillPlan* skillPlan in [context executeFetchRequest:request error:nil]) {
			NSMutableData* data = [NSMutableData new];
			NSKeyedArchiver* archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
			[archiver encodeObject:skillPlan.skills forKey:@"skills"];
			[archiver encodeObject:skillPlan.name forKey:@"name"];
			[archiver finishEncoding];
			NSString* item = [data md5];
			
			if ([items containsObject:item])
				[context deleteObject:skillPlan];
			else
				[items addObject:item];
		}
		
		request = [NSFetchRequest fetchRequestWithEntityName:@"DamagePattern"];
		items = [NSMutableSet new];
		for (NCDamagePattern* damagePattern in [context executeFetchRequest:request error:nil]) {
			NSString* item = [NSString stringWithFormat:@"%.2f,%.2f,%.2f,%.2f,%@", damagePattern.em, damagePattern.thermal, damagePattern.kinetic, damagePattern.explosive, damagePattern.name];
			if ([items containsObject:item])
				[context deleteObject:damagePattern];
			else
				[items addObject:item];
		}
		
		request = [NSFetchRequest fetchRequestWithEntityName:@"FitCharacter"];
		items = [NSMutableSet new];
		for (NCFitCharacter* fitCharacter in [context executeFetchRequest:request error:nil]) {
			NSMutableData* data = [NSMutableData new];
			NSKeyedArchiver* archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
			[archiver encodeObject:fitCharacter.skills forKey:@"skills"];
			[archiver encodeObject:fitCharacter.name forKey:@"name"];
			[archiver finishEncoding];
			NSString* item = [data md5];
			
			if ([items containsObject:item])
				[context deleteObject:fitCharacter];
			else
				[items addObject:item];
		}

		if ([context hasChanges])
			[context save:nil];
	}];
}

@end
