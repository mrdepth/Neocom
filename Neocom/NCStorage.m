//
//  NCStorage.m
//  Neocom
//
//  Created by Artem Shimanski on 25.01.13.
//
//

#import "NCStorage.h"
#import "UIAlertView+Error.h"
#import "NCAccount.h"
#import "NCLoadout.h"
#import "NCSkillPlan.h"
#import "NCDamagePattern.h"
#import "NCImplantSet.h"
#import "NCFitCharacter.h"

static NCStorage* sharedStorage;

@interface NCStorage()
@property (nonatomic, assign, readwrite) NCStorageType storageType;

- (void) didUpdateCloud:(NSNotification*) notification;
- (void) notifyStorageChange;

@end

@implementation NCStorage

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

+ (id) sharedStorage {
	@synchronized(self) {
//		if (!sharedStorage) {
//			sharedStorage = [[NCStorage alloc] init];
//		}
		return sharedStorage;
	}
}

+ (id) fallbackStorage {
	return [[self alloc] initFallbackStorage];
}

+ (id) cloudStorage {
	return [[self alloc] initCloudStorage];
}

+ (void) setSharedStorage:(NCStorage*) storage {
	@synchronized(self) {
		sharedStorage = storage;
	}
}


- (id) init {
	if (self = [super init]) {
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didUpdateCloud:) name:NSPersistentStoreDidImportUbiquitousContentChangesNotification object:nil];
	}
	return self;
}

- (id) initFallbackStorage {
	if (self = [self init]) {
		self.storageType = NCStorageTypeFallback;
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
																 options:nil
																   error:&error])
				break;
			else
				[[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil];
		}
		if (error) {
			dispatch_async(dispatch_get_main_queue(), ^{
				[[UIAlertView alertViewWithError:error] show];
			});
			return nil;
		}
		storeURL = [NSURL fileURLWithPath:[directory stringByAppendingPathComponent:@"localStore.sqlite"]];

		for (int n = 0; n < 2; n++) {
			error = nil;
			if ([_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
														  configuration:@"Local"
																	URL:storeURL
																options:nil
																  error:&error])
				break;
			else
				[[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil];
		}
		if (error) {
			dispatch_async(dispatch_get_main_queue(), ^{
				[[UIAlertView alertViewWithError:error] show];
			});
			return nil;
		}
	}
	return self;
}

- (id) initCloudStorage {
	if (self = [self init]) {
		self.storageType = NCStorageTypeCloud;
		BOOL useCloud = [[NSUserDefaults standardUserDefaults] boolForKey:NCSettingsUseCloudKey];
		if (!useCloud)
			return nil;
		
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

		NSDictionary* options = @{NSPersistentStoreUbiquitousContentNameKey : @"NCStorage",
								  NSPersistentStoreUbiquitousContentURLKey : url,
								  NSInferMappingModelAutomaticallyOption : @(YES),
								  NSMigratePersistentStoresAutomaticallyOption : @(YES)};

		
		
		_persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
		
		NSError *error = nil;
		for (int n = 0; n < 2; n++) {
			error = nil;
			if ([_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
														  configuration:@"Cloud"
																	URL:storeURL
																options:options
																  error:&error])
				break;
			else
				[[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil];
		}
		if (error) {
			dispatch_async(dispatch_get_main_queue(), ^{
				[[UIAlertView alertViewWithError:error] show];
			});
			return nil;
		}
		storeURL = [NSURL fileURLWithPath:[directory stringByAppendingPathComponent:@"localStore.sqlite"]];
		
		for (int n = 0; n < 2; n++) {
			error = nil;
			if ([_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
														  configuration:@"Local"
																	URL:storeURL
																options:nil
																  error:&error])
				break;
			else
				[[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil];
		}
		if (error) {
			dispatch_async(dispatch_get_main_queue(), ^{
				[[UIAlertView alertViewWithError:error] show];
			});
			return nil;
		}
	}
	return self;
}

- (void) dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NSPersistentStoreDidImportUbiquitousContentChangesNotification object:nil];
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

- (BOOL) transferDataFromFallbackToCloud {
	if (self.storageType != NCStorageTypeCloud)
		return NO;
	NCStorage* fallbackStorage = [NCStorage fallbackStorage];
	
	if (!fallbackStorage)
		return NO;

	[self.managedObjectContext performBlockAndWait:^{
		for (NCAccount* account in [fallbackStorage allAccounts]) {
			if (![self accountWithUUID:account.uuid]) {
				NCAccount* copyAccount = [NSEntityDescription insertNewObjectForEntityForName:@"Account" inManagedObjectContext:self.managedObjectContext];
				[copyAccount setValuesForKeysWithDictionary:[account dictionaryWithValuesForKeys:[[account.entity attributesByName] allKeys]]];
				
				copyAccount.apiKey = [NSEntityDescription insertNewObjectForEntityForName:@"APIKey" inManagedObjectContext:self.managedObjectContext];
				[copyAccount.apiKey setValuesForKeysWithDictionary:[account.apiKey dictionaryWithValuesForKeys:[[account.apiKey.entity attributesByName] allKeys]]];
				
				copyAccount.mailBox = [NSEntityDescription insertNewObjectForEntityForName:@"MailBox" inManagedObjectContext:self.managedObjectContext];
				[copyAccount.mailBox setValuesForKeysWithDictionary:[account.mailBox dictionaryWithValuesForKeys:[[account.mailBox.entity attributesByName] allKeys]]];
				
				for (NCSkillPlan* skillPlan in account.skillPlans) {
					NCSkillPlan* copySkillPlan = [NSEntityDescription insertNewObjectForEntityForName:@"SkillPlan" inManagedObjectContext:self.managedObjectContext];
					[copySkillPlan setValuesForKeysWithDictionary:[skillPlan dictionaryWithValuesForKeys:[[skillPlan.entity attributesByName] allKeys]]];
					copySkillPlan.account = copyAccount;
				}
			}
		}
		
		for (NCLoadout* loadout in [fallbackStorage loadouts]) {
			NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"Loadout"];
			request.entity = [NSEntityDescription entityForName:@"Loadout" inManagedObjectContext:self.managedObjectContext];
			request.predicate = [NSPredicate predicateWithFormat:@"typeID == %d AND data.data == %@", loadout.typeID, loadout.data.data];
			request.fetchLimit = 1;
			
			if ([self.managedObjectContext executeFetchRequest:request error:nil].count == 0) {
				NCLoadout* copyLoadout = [NSEntityDescription insertNewObjectForEntityForName:@"Loadout" inManagedObjectContext:self.managedObjectContext];
				[copyLoadout setValuesForKeysWithDictionary:[loadout dictionaryWithValuesForKeys:[[loadout.entity attributesByName] allKeys]]];
				
				copyLoadout.data = [NSEntityDescription insertNewObjectForEntityForName:@"LoadoutData" inManagedObjectContext:self.managedObjectContext];
				[copyLoadout.data setValuesForKeysWithDictionary:[loadout.data dictionaryWithValuesForKeys:[[loadout.data.entity attributesByName] allKeys]]];
			}
		}
		
		for (NCImplantSet* implantSet in [fallbackStorage implantSets]) {
			NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"ImplantSet"];
			request.entity = [NSEntityDescription entityForName:@"ImplantSet" inManagedObjectContext:self.managedObjectContext];
			request.predicate = [NSPredicate predicateWithFormat:@"name == %@ AND data == %@", implantSet.name, implantSet.data];
			request.fetchLimit = 1;
			
			if ([self.managedObjectContext executeFetchRequest:request error:nil].count == 0) {
				NCImplantSet* copyImplantSet = [NSEntityDescription insertNewObjectForEntityForName:@"ImplantSet" inManagedObjectContext:self.managedObjectContext];
				[copyImplantSet setValuesForKeysWithDictionary:[implantSet dictionaryWithValuesForKeys:[[implantSet.entity attributesByName] allKeys]]];
			}
		}
		
		for (NCDamagePattern* damagePattern in [fallbackStorage damagePatterns]) {
			NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"DamagePattern"];
			request.entity = [NSEntityDescription entityForName:@"DamagePattern" inManagedObjectContext:self.managedObjectContext];
			request.predicate = [NSPredicate predicateWithFormat:@"name == %@", damagePattern.name];
			request.fetchLimit = 1;
			
			if ([self.managedObjectContext executeFetchRequest:request error:nil].count == 0) {
				NCDamagePattern* copyDamagePattern = [NSEntityDescription insertNewObjectForEntityForName:@"DamagePattern" inManagedObjectContext:self.managedObjectContext];
				[copyDamagePattern setValuesForKeysWithDictionary:[damagePattern dictionaryWithValuesForKeys:[[damagePattern.entity attributesByName] allKeys]]];
			}
		}
		
		for (NCFitCharacter* character in [fallbackStorage characters]) {
			NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"FitCharacter"];
			request.entity = [NSEntityDescription entityForName:@"FitCharacter" inManagedObjectContext:self.managedObjectContext];
			request.predicate = [NSPredicate predicateWithFormat:@"name == %@", character.name];
			request.fetchLimit = 1;
			
			if ([self.managedObjectContext executeFetchRequest:request error:nil].count == 0) {
				NCFitCharacter* copyCharacter = [NSEntityDescription insertNewObjectForEntityForName:@"FitCharacter" inManagedObjectContext:self.managedObjectContext];
				[copyCharacter setValuesForKeysWithDictionary:[character dictionaryWithValuesForKeys:[[character.entity attributesByName] allKeys]]];
			}
		}
		
		[self saveContext];
	}];

	return YES;
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
		if (_persistentStoreCoordinator != nil)
			return _persistentStoreCoordinator;
		
		NSString* directory = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES)[0] stringByAppendingPathComponent:@"com.shimanski.neocom.store"];
		[[NSFileManager defaultManager] createDirectoryAtPath:directory withIntermediateDirectories:YES attributes:nil error:nil];
		NSURL *storeURL = [NSURL fileURLWithPath:[directory stringByAppendingPathComponent:@"cloudStore.sqlite"]];

		BOOL useCloud = [[NSUserDefaults standardUserDefaults] boolForKey:NCSettingsUseCloudKey];
		NSDictionary* options = nil;
		if (useCloud) {
			id currentCloudToken = [[NSFileManager defaultManager] ubiquityIdentityToken];
			if (!currentCloudToken)
				useCloud = NO;
			if (useCloud) {
				NSURL* url = [[NSFileManager defaultManager] URLForUbiquityContainerIdentifier:nil];
				if (!url)
					useCloud = NO;
				if (useCloud) {
					id lastCloudToken = [[NSFileManager defaultManager] ubiquityIdentityToken];
					NSData *tokenData = [[NSUserDefaults standardUserDefaults] valueForKey:NCSettingsCloudTokenKey];
					if (tokenData)
						lastCloudToken = [NSKeyedUnarchiver unarchiveObjectWithData:tokenData];
					
					if (lastCloudToken && ![lastCloudToken isEqual:currentCloudToken]) {
						[[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil];
					}
					
					tokenData = [NSKeyedArchiver archivedDataWithRootObject: currentCloudToken];
					[[NSUserDefaults standardUserDefaults] setObject: tokenData forKey:NCSettingsCloudTokenKey];
					[[NSUserDefaults standardUserDefaults] synchronize];
					options = @{NSPersistentStoreUbiquitousContentNameKey : @"NCStorage",
								NSPersistentStoreUbiquitousContentURLKey : url,
								NSInferMappingModelAutomaticallyOption : @(YES),
								NSMigratePersistentStoresAutomaticallyOption : @(YES)};
				}
			}
		}
		
		_persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
		
		NSError *error = nil;
		if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
													  configuration:@"Cloud"
																URL:storeURL
															options:options
															   error:&error]) {
			[[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil];
			if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
													  configuration:@"Cloud"
																URL:storeURL
															options:options
																   error:&error]) {
				dispatch_async(dispatch_get_main_queue(), ^{
					[[UIAlertView alertViewWithError:error] show];
				});
				_persistentStoreCoordinator = nil;
				return _persistentStoreCoordinator;
			}
		}

		storeURL = [NSURL fileURLWithPath:[directory stringByAppendingPathComponent:@"localStore.sqlite"]];
		error = nil;
		
		if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
													   configuration:@"Local"
																 URL:storeURL
															 options:nil
															   error:&error]) {
			[[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil];
			if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
														   configuration:@"Local"
																	 URL:storeURL
																 options:nil
																   error:&error]) {
				dispatch_async(dispatch_get_main_queue(), ^{
					[[UIAlertView alertViewWithError:error] show];
				});
				_persistentStoreCoordinator = nil;
				return _persistentStoreCoordinator;
			}
		}
		return _persistentStoreCoordinator;
	}
}

#pragma mark - Private

- (void) didUpdateCloud:(NSNotification*) notification {
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
}

- (void) notifyStorageChange {
	NCAccount* account = [NCAccount currentAccount];
	if ([NSThread isMainThread]) {
		if (account && !account.managedObjectContext)
			[NCAccount setCurrentAccount:nil];
		[[NSNotificationCenter defaultCenter] postNotificationName:NCStorageDidChangeNotification object:self userInfo:nil];
	}
	else {
		dispatch_async(dispatch_get_main_queue(), ^{
			if (account && !account.managedObjectContext)
				[NCAccount setCurrentAccount:nil];
			[[NSNotificationCenter defaultCenter] postNotificationName:NCStorageDidChangeNotification object:self userInfo:nil];
		});
	}
}

@end
