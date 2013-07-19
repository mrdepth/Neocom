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

- (void) manageAPIKey:(APIKey*) apiKey;
@end

@implementation EVEAccountsManager

+ (EVEAccountsManager*) sharedManager {
	@synchronized(self) {
		if (!sharedManager)
			sharedManager = [[EVEAccountsManager alloc] init];
		return sharedManager;
	}
}

- (void) reload {
	@synchronized(self) {
		self.ignored = [[NSMutableDictionary alloc] init];
		for (IgnoredCharacter* character in [IgnoredCharacter allIgnoredCharacters])
			self.ignored[@(character.characterID)] = character;
		
		self.accounts = [[NSMutableDictionary alloc] init];
		for (APIKey* apiKey in [APIKey allAPIKeys]) {
			NSError* error = nil;
			apiKey.apiKeyInfo = [EVEAPIKeyInfo apiKeyInfoWithKeyID:apiKey.keyID vCode:apiKey.vCode error:&error progressHandler:nil];
			apiKey.error = error;
			[self manageAPIKey:apiKey];
		}
		self.allAccounts = [[self.accounts allValues] sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"characterName" ascending:YES]]];
	}
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
			NSManagedObjectContext* context = [[EUStorage sharedStorage] managedObjectContext];
			[context performBlockAndWait:^{
				APIKey* apiKey = nil;
				for (apiKey in [APIKey allAPIKeys])
					if (apiKey.keyID == keyID)
						break;
				if (!apiKey) {
					apiKey = [[APIKey alloc] initWithEntity:[NSEntityDescription entityForName:@"APIKey" inManagedObjectContext:context] insertIntoManagedObjectContext:context];
					apiKey.keyID = keyID;
				}
				apiKey.vCode = vCode;
				apiKey.apiKeyInfo = apiKeyInfo;
				[[EUStorage sharedStorage] saveContext];
				
				[self manageAPIKey:apiKey];
				self.allAccounts = [[self.accounts allValues] sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"characterName" ascending:YES]]];
			}];
		}
	}
	return YES;
}

- (void) removeAPIKeyWithKeyID:(NSInteger) keyID {
	@synchronized(self) {
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
					[account.apiKeys removeObject:apiKey];
					if (account.charAPIKey == apiKey)
						account.charAPIKey = nil;
					else if (account.corpAPIKey == apiKey)
						account.corpAPIKey = nil;
					if (account.apiKeys.count == 0)
						[self.accounts removeObjectForKey:@(account.character.characterID)];
				}
				[context deleteObject:apiKey];
				[[EUStorage sharedStorage] saveContext];
			}
		}];
	}
}

#pragma mark - Private

- (void) manageAPIKey:(APIKey*) apiKey {
	for (EVEAPIKeyInfoCharactersItem* character in apiKey.apiKeyInfo.characters) {
		EVEAccount* account = self.accounts[@(character.characterID)];
		if (!account) {
			account = [[EVEAccount alloc] init];
			account.character = character;
			self.accounts[@(character.characterID)] = account;
		}
		[account.apiKeys addObject:apiKey];
		if (apiKey.apiKeyInfo.key.type == EVEAPIKeyTypeCorporation && !account.corpAPIKey)
			account.corpAPIKey = apiKey;
		else if (apiKey.apiKeyInfo.key.type != EVEAPIKeyTypeCorporation && !account.charAPIKey)
			account.charAPIKey = apiKey;
		
		account.ignored = self.ignored[@(character.characterID)] != nil;
	}
}

@end
