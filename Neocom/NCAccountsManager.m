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

static NCAccountsManager* defaultManager = nil;

@interface NCAccountsManager()
@property (nonatomic, strong, readwrite) NSArray* accounts;
@property (nonatomic, strong, readwrite) NSArray* apiKeys;
@end

@implementation NCAccountsManager

+ (instancetype) defaultManager {
	@synchronized(self) {
		if (!defaultManager)
			defaultManager = [NCAccountsManager new];
		return defaultManager;
	}
}

+ (void) cleanup {
	@synchronized(self) {
		defaultManager = nil;
	}
}

- (BOOL) addAPIKeyWithKeyID:(NSInteger) keyID vCode:(NSString*) vCode error:(NSError**) errorPtr {
	NCStorage* storage = [NCStorage sharedStorage];
	NSManagedObjectContext* context = storage.managedObjectContext;
	
	EVEAPIKeyInfo* apiKeyInfo = [EVEAPIKeyInfo apiKeyInfoWithKeyID:keyID vCode:vCode cachePolicy:NSURLRequestReloadIgnoringLocalCacheData error:errorPtr progressHandler:nil];
	
	if (apiKeyInfo) {
		__block NCAPIKey* apiKey = nil;
		
		[context performBlockAndWait:^{
			apiKey = [NCAPIKey apiKeyWithKeyID:keyID];
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
					account.order = NSIntegerMax;
					account.uuid = [[NSUUID UUID] UUIDString];
				}
			}
			
			self.accounts = [NCAccount allAccounts];
			self.apiKeys = [NCAPIKey allAPIKeys];
			NSInteger order = 0;
			for (NCAccount* account in self.accounts)
				account.order = order++;
			
			[storage saveContext];
		}];
		[[NCNotificationsManager sharedManager] setNeedsUpdateNotifications];
		return YES;
	}
	else
		return NO;
}


- (void) removeAccount:(NCAccount*) account {
	NCStorage* storage = [NCStorage sharedStorage];
	[storage.managedObjectContext performBlockAndWait:^{
		if ([NCAccount currentAccount] == account)
			[NCAccount setCurrentAccount:nil];

		NCAPIKey* apiKey = account.apiKey;
		[storage.managedObjectContext deleteObject:account];
		
		if (apiKey.accounts.count == 0)
			[storage.managedObjectContext deleteObject:apiKey];
		
		self.accounts = [NCAccount allAccounts];
		self.apiKeys = [NCAPIKey allAPIKeys];
		NSInteger order = 0;
		for (NCAccount* account in self.accounts)
			account.order = order++;
		
		[storage saveContext];
	}];
	[[NCNotificationsManager sharedManager] setNeedsUpdateNotifications];
}

- (void) reload {
	@synchronized(self) {
		_accounts = [NCAccount allAccounts];
		_apiKeys = [NCAPIKey allAPIKeys];
	}
}

- (NSArray*) accounts {
	@synchronized(self) {
		if (!_accounts) {
			_accounts = [NCAccount allAccounts];
		}
		return _accounts;
	}
}

- (NSArray*) apiKeys {
	@synchronized(self) {
		if (!_apiKeys) {
			_apiKeys = [NCAPIKey allAPIKeys];
		}
		return _apiKeys;
	}
}

@end
