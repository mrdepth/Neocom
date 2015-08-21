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
@property (nonatomic, strong) NSManagedObjectContext* managedObjectContext;
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
		self.managedObjectContext = [storage createManagedObjectContext];
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didChangeStorage:) name:NCStorageDidChangeNotification object:nil];
		self.storage = storage;
	}
	return self;
}

- (void) dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NCStorageDidChangeNotification object:nil];
}

- (void) addAPIKeyWithKeyID:(int32_t) keyID vCode:(NSString*) vCode completionBlock:(void(^)(NSArray* accounts, NSError* error)) completionBlock {
	EVEOnlineAPI* api = [EVEOnlineAPI apiWithAPIKey:[EVEAPIKey apiKeyWithKeyID:keyID vCode:vCode] cachePolicy:NSURLRequestReloadIgnoringLocalCacheData];
	[api apiKeyInfoWithCompletionBlock:^(EVEAPIKeyInfo *result, NSError *error) {
		if (result && !result.eveapi.error) {
			[self.managedObjectContext performBlock:^{
				NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
				fetchRequest.predicate = [NSPredicate predicateWithFormat:@"keyID == %d", keyID];
				fetchRequest.fetchLimit = 1;
				NSEntityDescription *entity = [NSEntityDescription entityForName:@"APIKey" inManagedObjectContext:self.managedObjectContext];
				[fetchRequest setEntity:entity];
				NCAPIKey* apiKey = [[self.managedObjectContext executeFetchRequest:fetchRequest error:nil] lastObject];
				
				if (apiKey && ![apiKey.vCode isEqualToString:vCode]) {
					[self.managedObjectContext deleteObject:apiKey];
					apiKey = nil;
				}

				if (!apiKey) {
					apiKey = [[NCAPIKey alloc] initWithEntity:[NSEntityDescription entityForName:@"APIKey" inManagedObjectContext:self.managedObjectContext] insertIntoManagedObjectContext:self.managedObjectContext];
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
						account = [[NCAccount alloc] initWithEntity:[NSEntityDescription entityForName:@"Account" inManagedObjectContext:self.managedObjectContext] insertIntoManagedObjectContext:self.managedObjectContext];
						account.apiKey = apiKey;
						account.characterID = character.characterID;
						account.order = INT32_MAX;
						account.uuid = [[NSUUID UUID] UUIDString];
						[accounts addObject:account];
					}
				}

				int32_t order = 0;
				for (NCAccount* account in [self.managedObjectContext allAccounts])
					account.order = order++;
				
				if ([self.managedObjectContext hasChanges])
					[self.managedObjectContext save:nil];
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
	[self.managedObjectContext performBlock:^{
		if ([NCAccount currentAccount] == account)
			[NCAccount setCurrentAccount:nil];

		NCAPIKey* apiKey = account.apiKey;
		[self.managedObjectContext deleteObject:account];
		
		if (apiKey.accounts.count == 0)
			[self.managedObjectContext deleteObject:apiKey];
		
		int32_t order = 0;
		for (NCAccount* account in [self.managedObjectContext allAccounts])
			account.order = order++;
		
		if ([self.managedObjectContext hasChanges])
			[self.managedObjectContext save:nil];
	}];
	[[NCNotificationsManager sharedManager] setNeedsUpdateNotifications];
}

- (void) loadAccountsWithCompletionBlock:(void(^)(NSArray* accounts)) completionBlock {
	[self.managedObjectContext performBlock:^{
		NSArray* accounts = [self.managedObjectContext allAccounts];
		if (completionBlock)
			dispatch_async(dispatch_get_main_queue(), ^{
				completionBlock(accounts);
			});
	}];
}

#pragma mark - Private

- (void) didChangeStorage:(NSNotification*) notification {
//	self.storage = [NCStorage sharedStorage];
//	self.managedObjectContext = [self.storage createManagedObjectContext];
}

@end
