//
//  NCAccountsManager.m
//  Neocom
//
//  Created by Artem Shimanski on 18.12.13.
//  Copyright (c) 2013 Artem Shimanski. All rights reserved.
//

#import "NCAccountsManager.h"
#import "NCStorage.h"
#import "NCCache.h"
#import "NCNotificationsManager.h"
#import "NSManagedObjectContext+NCStorage.h"

static NCAccountsManager* sharedManager = nil;

@interface NCAccountsManager()
@property (nonatomic, strong, readwrite) NCStorage* storage;

- (void) didChangeStorage:(NSNotification*) notification;
- (void) managedObjectContextDidSave:(NSNotification*) notification;

@end

@implementation NCAccountsManager

+ (instancetype) sharedManager {
	@synchronized(self) {
		return sharedManager;
	}
}

+ (void) setSharedManager:(NCAccountsManager*) manager {
	@synchronized(self) {
		sharedManager = manager;
	}
}

- (id) initWithStorage:(NCStorage*) storage {
	assert(storage);
	if (self = [super init]) {
		self.storageManagedObjectContext = [storage createManagedObjectContext];
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didChangeStorage:) name:NCStorageDidChangeNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(managedObjectContextDidSave:) name:NSManagedObjectContextDidSaveNotification object:nil];

		self.storage = storage;
	}
	return self;
}

- (void) dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void) addAPIKeyWithKeyID:(int32_t) keyID vCode:(NSString*) vCode completionBlock:(void(^)(NSArray* accounts, NSError* error)) completionBlock {
	EVEOnlineAPI* api = [EVEOnlineAPI apiWithAPIKey:[EVEAPIKey apiKeyWithKeyID:keyID vCode:vCode] cachePolicy:NSURLRequestReloadIgnoringLocalCacheData];
	[api apiKeyInfoWithCompletionBlock:^(EVEAPIKeyInfo *result, NSError *error) {
		if (result && !result.eveapi.error) {
			[self.storageManagedObjectContext performBlock:^{
				NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
				fetchRequest.predicate = [NSPredicate predicateWithFormat:@"keyID == %d", keyID];
				fetchRequest.fetchLimit = 1;
				NSEntityDescription *entity = [NSEntityDescription entityForName:@"APIKey" inManagedObjectContext:self.storageManagedObjectContext];
				[fetchRequest setEntity:entity];
				NCAPIKey* apiKey = [[self.storageManagedObjectContext executeFetchRequest:fetchRequest error:nil] lastObject];
				
				if (apiKey && ![apiKey.vCode isEqualToString:vCode]) {
					[self.storageManagedObjectContext deleteObject:apiKey];
					apiKey = nil;
				}

				if (!apiKey) {
					apiKey = [[NCAPIKey alloc] initWithEntity:[NSEntityDescription entityForName:@"APIKey" inManagedObjectContext:self.storageManagedObjectContext] insertIntoManagedObjectContext:self.storageManagedObjectContext];
					apiKey.keyID = keyID;
					apiKey.vCode = vCode;
					apiKey.apiKeyInfo = result;
				}
				
				NSMutableArray* accounts = [NSMutableArray new];
				for (EVEAPIKeyInfoCharactersItem* character in result.key.characters) {
					NCAccount* account = nil;
					for (account in apiKey.accounts)
						if (account.characterID == character.characterID)
							break;
					if (!account) {
						account = [[NCAccount alloc] initWithEntity:[NSEntityDescription entityForName:@"Account" inManagedObjectContext:self.storageManagedObjectContext] insertIntoManagedObjectContext:self.storageManagedObjectContext];
						account.apiKey = apiKey;
						account.characterID = character.characterID;
						account.order = INT32_MAX;
						account.uuid = [[NSUUID UUID] UUIDString];
						[accounts addObject:account];
					}
				}

				int32_t order = 0;
				for (NCAccount* account in [self.storageManagedObjectContext allAccounts])
					account.order = order++;
				
				if ([self.storageManagedObjectContext hasChanges])
					[self.storageManagedObjectContext save:nil];
				dispatch_async(dispatch_get_main_queue(), ^{
					completionBlock(accounts, nil);
				});
			}];
		}
		else
			completionBlock(nil, error ?: result.eveapi.error);
	} progressBlock:nil];
}

- (void) removeAccount:(NCAccount*) account {
	[self.storageManagedObjectContext performBlock:^{
		if ([NCAccount currentAccount] == account)
			[NCAccount setCurrentAccount:nil];

		NCAPIKey* apiKey = account.apiKey;
		[self.storageManagedObjectContext deleteObject:account];
		
		if (apiKey.accounts.count == 0)
			[self.storageManagedObjectContext deleteObject:apiKey];
		
		int32_t order = 0;
		for (NCAccount* account in [self.storageManagedObjectContext allAccounts])
			account.order = order++;
		
		if ([self.storageManagedObjectContext hasChanges])
			[self.storageManagedObjectContext save:nil];
	}];
	[[NCNotificationsManager sharedManager] setNeedsUpdateNotifications];
}

- (void) loadAccountsWithCompletionBlock:(void(^)(NSArray* accounts, NSArray* apiKeys)) completionBlock {
	[self.storageManagedObjectContext performBlock:^{
		NSArray* accounts = [self.storageManagedObjectContext allAccounts];
		NSArray* apiKeys = [self.storageManagedObjectContext allAPIKeys];
		
		dispatch_group_t finishDispatchGroup = dispatch_group_create();
		for (NCAPIKey* apiKey in apiKeys) {
			if (!apiKey.apiKeyInfo) {
				dispatch_group_enter(finishDispatchGroup);
				EVEOnlineAPI* api = [[EVEOnlineAPI alloc] initWithAPIKey:[[EVEAPIKey alloc] initWithKeyID:apiKey.keyID vCode:apiKey.vCode] cachePolicy:NSURLRequestUseProtocolCachePolicy];
				[api apiKeyInfoWithCompletionBlock:^(EVEAPIKeyInfo *result, NSError *error) {
					if (result) {
						[apiKey.managedObjectContext performBlock:^{
							apiKey.apiKeyInfo = result;
							dispatch_group_leave(finishDispatchGroup);
						}];
					}
					else
						dispatch_group_leave(finishDispatchGroup);
				} progressBlock:nil];
			}
		}
		
		dispatch_group_notify(finishDispatchGroup, dispatch_get_main_queue(), ^{
			[self.storageManagedObjectContext performBlock:^{
				NSArray* validAccounts = [accounts filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"apiKey.apiKeyInfo <> NULL"]];
				NSArray* validKeys = [apiKeys filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"apiKeyInfo <> NULL"]];
				
				if (completionBlock)
					dispatch_async(dispatch_get_main_queue(), ^{
						completionBlock(validAccounts, validKeys);
					});

			}];
		});
		
	}];
}

#pragma mark - Private

- (void) didChangeStorage:(NSNotification*) notification {
//	self.storage = [NCStorage sharedStorage];
//	self.managedObjectContext = [self.storage createManagedObjectContext];
}

- (void) managedObjectContextDidSave:(NSNotification*) notification {
	NSManagedObjectContext* context = notification.object;
	if (context.persistentStoreCoordinator == _storageManagedObjectContext.persistentStoreCoordinator) {
		[self.storageManagedObjectContext performBlock:^{
			[self.storageManagedObjectContext mergeChangesFromContextDidSaveNotification:notification];
		}];
	}
}

@end
