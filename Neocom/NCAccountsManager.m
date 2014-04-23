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

static NCAccountsManager* sharedManager = nil;

@interface NCAccountsManager()
@property (nonatomic, strong, readwrite) NSArray* accounts;
@property (nonatomic, strong, readwrite) NSArray* apiKeys;
@property (nonatomic, strong, readwrite) NCStorage* storage;
- (void) didChangeStorage:(NSNotification*) notification;

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
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didChangeStorage:) name:NCStorageDidChangeNotification object:nil];
		self.storage = storage;
	}
	return self;
}

- (void) dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NCStorageDidChangeNotification object:nil];
}

- (BOOL) addAPIKeyWithKeyID:(int32_t) keyID vCode:(NSString*) vCode error:(NSError**) errorPtr {
	NSManagedObjectContext* context = self.storage.managedObjectContext;
	
	EVEAPIKeyInfo* apiKeyInfo = [EVEAPIKeyInfo apiKeyInfoWithKeyID:keyID vCode:vCode cachePolicy:NSURLRequestReloadIgnoringLocalCacheData error:errorPtr progressHandler:nil];
	
	if (apiKeyInfo) {
		__block NCAPIKey* apiKey = nil;
		
		[context performBlockAndWait:^{
			apiKey = [self.storage apiKeyWithKeyID:keyID];
			if (apiKey && ![apiKey.vCode isEqualToString:vCode]) {
				[context deleteObject:apiKey];
				apiKey = nil;
			}
			
			if (!apiKey) {
				apiKey = [[NCAPIKey alloc] initWithEntity:[NSEntityDescription entityForName:@"APIKey" inManagedObjectContext:context] insertIntoManagedObjectContext:context];
				apiKey.keyID = keyID;
				apiKey.vCode = vCode;
				apiKey.apiKeyInfo = apiKeyInfo;
			}
			
			for (EVEAPIKeyInfoCharactersItem* character in apiKeyInfo.characters) {
				NCAccount* account = nil;
				for (account in apiKey.accounts)
					if (account.characterID == character.characterID)
						break;
				if (!account) {
					account = [[NCAccount alloc] initWithEntity:[NSEntityDescription entityForName:@"Account" inManagedObjectContext:context] insertIntoManagedObjectContext:context];
					account.apiKey = apiKey;
					account.characterID = character.characterID;
					account.order = INT32_MAX;
					account.uuid = [[NSUUID UUID] UUIDString];
				}
			}
			
			self.accounts = [self.storage allAccounts];
			self.apiKeys = [self.storage allAPIKeys];
			int32_t order = 0;
			for (NCAccount* account in self.accounts)
				account.order = order++;
			
			[self.storage saveContext];
		}];
		[[NCNotificationsManager sharedManager] setNeedsUpdateNotifications];
		return YES;
	}
	else
		return NO;
}


- (void) removeAccount:(NCAccount*) account {
	[self.storage.managedObjectContext performBlockAndWait:^{
		if ([NCAccount currentAccount] == account)
			[NCAccount setCurrentAccount:nil];

		NCAPIKey* apiKey = account.apiKey;
		[self.storage.managedObjectContext deleteObject:account];
		
		if (apiKey.accounts.count == 0)
			[self.storage.managedObjectContext deleteObject:apiKey];
		
		self.accounts = [self.storage allAccounts];
		self.apiKeys = [self.storage allAPIKeys];
		int32_t order = 0;
		for (NCAccount* account in self.accounts)
			account.order = order++;
		
		[self.storage saveContext];
	}];
	[[NCNotificationsManager sharedManager] setNeedsUpdateNotifications];
}

- (void) reload {
	@synchronized(self) {
		_accounts = [self.storage allAccounts];
		_apiKeys = [self.storage allAPIKeys];
	}
}

- (NSArray*) accounts {
	@synchronized(self) {
		if (!_accounts) {
			_accounts = [self.storage allAccounts];
		}
		return _accounts;
	}
}

- (NSArray*) apiKeys {
	@synchronized(self) {
		if (!_apiKeys) {
			_apiKeys = [self.storage allAPIKeys];
		}
		return _apiKeys;
	}
}

#pragma mark - Private

- (void) didChangeStorage:(NSNotification*) notification {
	[self reload];
}

@end
