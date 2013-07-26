//
//  EVEAccountsManager.m
//  EVEUniverse
//
//  Created by TANYA on 18.07.13.
//
//

#import "EVEAccountsManager.h"
#import "EVEAccount.h"
#import "EUStorage.h"
#import "IgnoredCharacter.h"

static EVEAccountsManager* sharedManager = nil;

@interface EVEAccountsManager()
@property (nonatomic, strong) NSMutableDictionary* accounts;
@property (nonatomic, strong) NSMutableDictionary* ignored;
@property (nonatomic, strong) NSMutableDictionary* reusedAccounts;

- (void) manageAPIKey:(APIKey*) apiKey;
@end

@implementation EVEAccountsManager

+ (EVEAccountsManager*) sharedManager {
	return sharedManager;
}

+ (void) setSharedManager:(EVEAccountsManager*) manager {
	sharedManager = manager;
}

- (void) reload {
	@synchronized(self) {
		self.ignored = [[NSMutableDictionary alloc] init];
		for (IgnoredCharacter* character in [IgnoredCharacter allIgnoredCharacters])
			self.ignored[@(character.characterID)] = character;
		
		self.reusedAccounts = self.accounts;
		self.accounts = [[NSMutableDictionary alloc] init];
		for (APIKey* apiKey in [APIKey allAPIKeys]) {
			apiKey.apiKeyInfo = nil;
			[apiKey apiKeyInfo];
			[self manageAPIKey:apiKey];
		}
		self.allAccounts = [self.accounts allValues];
		self.reusedAccounts = nil;
	}
}

- (EVEAccount*) accountWithCharacterID:(NSInteger) characterID {
	return self.accounts[@(characterID)];
}

- (BOOL) addAPIKeyWithKeyID:(NSInteger) keyID vCode:(NSString*) vCode error:(NSError**) errorPtr {
	NSError *error = nil;
	EVEAPIKeyInfo *apiKeyInfo = [EVEAPIKeyInfo apiKeyInfoWithKeyID:keyID vCode:vCode error:&error progressHandler:nil];

	if (error) {
		if (errorPtr)
			*errorPtr = error;
		return NO;
	}
	else {
		@synchronized(self) {
			NSMutableSet* inserted = [[NSMutableSet alloc] init];
			NSMutableSet* updated = [[NSMutableSet alloc] init];
			NSMutableSet* deleted = [[NSMutableSet alloc] init];

			NSManagedObjectContext* context = [[EUStorage sharedStorage] managedObjectContext];
			[context performBlockAndWait:^{
				APIKey* apiKey = nil;
				for (apiKey in [APIKey allAPIKeys])
					if (apiKey.keyID == keyID)
						break;
				
				if (!apiKey) {
					apiKey = [[APIKey alloc] initWithEntity:[NSEntityDescription entityForName:@"APIKey" inManagedObjectContext:context] insertIntoManagedObjectContext:context];
					apiKey.keyID = keyID;
					[inserted addObject:apiKey];
				}
				else {
					for (EVEAccount* account in self.allAccounts) {
						if ([account.apiKeys containsObject:apiKey]) {
							NSMutableArray* apiKeys = [[NSMutableArray alloc] initWithArray:account.apiKeys];
							[apiKeys removeObject:apiKey];
							account.apiKeys = apiKeys;

							account.charAPIKey = nil;
							account.corpAPIKey = nil;
							[updated addObject:account];
						}
					}
					[updated addObject:apiKey];
				}
				
				apiKey.vCode = vCode;
				apiKey.apiKeyInfo = apiKeyInfo;
				[[EUStorage sharedStorage] saveContext];
				
				NSMutableSet* accounts0 = [NSMutableSet setWithArray:self.allAccounts];
				
				[self manageAPIKey:apiKey];
				self.allAccounts = [self.accounts allValues];
				
				for (EVEAccount* account in self.allAccounts) {
					if ([account.apiKeys containsObject:apiKey]) {
						[updated addObject:account];
					}
				}

				
				NSMutableSet* accounts1 = [NSMutableSet setWithArray:self.allAccounts];
				NSMutableSet* accounts2 = [NSMutableSet setWithSet:accounts0];
				
				[accounts2 minusSet:accounts1];
				[accounts1 minusSet:accounts0];

				[inserted unionSet:accounts1];
				[deleted unionSet:accounts2];
				[updated minusSet:deleted];
				[updated minusSet:inserted];
			}];
			
			void (^notify)() = ^() {
				NSMutableDictionary* userInfo = [[NSMutableDictionary alloc] init];
				if (inserted.count > 0)
					userInfo[EVEAccountsManagerInsertedObjectsKey] = inserted;
				if (deleted.count > 0)
					userInfo[EVEAccountsManagerDeletedObjectsKey] = deleted;
				if (updated.count > 0)
					userInfo[EVEAccountsManagerUpdatedObjectsKey] = updated;
				[[NSNotificationCenter defaultCenter] postNotificationName:EVEAccountsManagerDidChangeNotification object:self userInfo:userInfo];
			};
			
			if (dispatch_get_current_queue() == dispatch_get_main_queue())
				notify();
			else
				dispatch_async(dispatch_get_main_queue(), notify);

		}
	}
	return YES;
}

- (void) removeAPIKeyWithKeyID:(NSInteger) keyID {
	@synchronized(self) {
		NSMutableSet* deleted = [[NSMutableSet alloc] init];
		NSMutableSet* updated = [[NSMutableSet alloc] init];

		NSManagedObjectContext* context = [[EUStorage sharedStorage] managedObjectContext];
		[context performBlockAndWait:^{
			NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
			NSEntityDescription *entity = [NSEntityDescription entityForName:@"APIKey" inManagedObjectContext:context];
			[fetchRequest setEntity:entity];
			
			NSPredicate *predicate = [NSPredicate predicateWithFormat:@"keyID == %d", keyID];
			[fetchRequest setPredicate:predicate];
			
			NSArray *fetchedObjects = [context executeFetchRequest:fetchRequest error:nil];
			if (fetchedObjects.count > 0) {
				APIKey* apiKey = fetchedObjects[0];
				for (EVEAccount* account in [self.accounts allValues]) {
					if ([account.apiKeys containsObject:apiKey]) {
						NSMutableArray* apiKeys = [[NSMutableArray alloc] initWithArray:account.apiKeys];
						[apiKeys removeObject:apiKey];
						account.apiKeys = apiKeys;
						
						account.charAPIKey = nil;
						account.corpAPIKey = nil;
						if (account.apiKeys.count == 0) {
							[deleted addObject:account];
							[self.accounts removeObjectForKey:@(account.character.characterID)];
						}
						else
							[updated addObject:account];
					}
				}
				[deleted addObject:apiKey];
				[context deleteObject:apiKey];
				
				self.allAccounts = [self.accounts allValues];
			}
		}];
		
		void (^notify)() = ^() {
			NSMutableDictionary* userInfo = [[NSMutableDictionary alloc] init];
			userInfo[EVEAccountsManagerDeletedObjectsKey] = deleted;
			if (updated.count > 0)
				userInfo[EVEAccountsManagerUpdatedObjectsKey] = updated;
			[[NSNotificationCenter defaultCenter] postNotificationName:EVEAccountsManagerDidChangeNotification object:self userInfo:userInfo];
			[[EUStorage sharedStorage] saveContext];
		};
		
		if ([NSThread isMainThread])
			notify();
		else
			dispatch_async(dispatch_get_main_queue(), notify);

	}
}

#pragma mark - Private

- (void) manageAPIKey:(APIKey*) apiKey {
	for (EVEAPIKeyInfoCharactersItem* character in apiKey.apiKeyInfo.characters) {
		EVEAccount* account = self.accounts[@(character.characterID)];
		if (!account) {
			account = self.reusedAccounts[@(character.characterID)];
			if (account) {
				account.apiKeys = nil;
				account.charAPIKey = nil;
				account.corpAPIKey = nil;
			}
			else {
				account = [[EVEAccount alloc] init];
			}
			account.character = character;
			self.accounts[@(character.characterID)] = account;
		}
		if (account.apiKeys)
			account.apiKeys = [account.apiKeys arrayByAddingObject:apiKey];
		else
			account.apiKeys = @[apiKey];
		account.ignored = self.ignored[@(character.characterID)] != nil;
	}
}

@end
