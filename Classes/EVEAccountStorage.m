//
//  EVEAccountStorage.m
//  EVEUniverse
//
//  Created by Shimanski on 8/31/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "EVEAccountStorage.h"
#import "Globals.h"

@implementation EVEAccountStorage
@synthesize apiKeys;
@synthesize characters;
@synthesize ignored;

- (id) init {
	if (self = [super init]) {
	}
	return self;
}

- (void) dealloc {
	[apiKeys release];
	for (EVEAccountStorageCharacter *character in [characters allValues])
		[character removeObserver:self forKeyPath:@"enabled"];
	[characters release];
	[ignored release];
	[super dealloc];
}

+ (EVEAccountStorage*) sharedAccountStorage {
	return [[Globals appDelegate] sharedAccountStorage];
}

- (void) reload {
	@synchronized(self) {
		if (apiKeys)
			[apiKeys release];
		if (characters) {
			for (EVEAccountStorageCharacter *character in [characters allValues])
				[character removeObserver:self forKeyPath:@"enabled"];
			[characters release];
		}
		
		if (ignored)
			[ignored release];
		
		apiKeys = [[NSMutableDictionary alloc] init];
		characters = [[NSMutableDictionary alloc] init];
		ignored = [[NSMutableSet alloc] init];
		
		
		NSString *path = [Globals accountsFilePath];
		NSDictionary *storage = [NSDictionary dictionaryWithContentsOfURL:[NSURL fileURLWithPath:path]];
		[ignored addObjectsFromArray:[storage valueForKey:@"ignored"]];
		NSMutableArray *accounts = [storage valueForKey:@"apiKeys"];
		
		NSOperationQueue *queue = [[NSOperationQueue alloc] init];
		for (NSDictionary *account in accounts) {
			EVEAccountStorageAPIKey *apiKey = [[[EVEAccountStorageAPIKey alloc] init] autorelease];
			apiKey.keyID = [[account valueForKey:@"keyID"] integerValue];
			apiKey.vCode = [account valueForKey:@"vCode"];
			[apiKeys setValue:apiKey forKey:[NSString stringWithFormat:@"%d", apiKey.keyID]];
			
			NSBlockOperation *operation = [NSBlockOperation blockOperationWithBlock:^(void) {
				NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
				NSError *error = nil;
				EVEAPIKeyInfo *apiKeyInfo = [EVEAPIKeyInfo apiKeyInfoWithKeyID:apiKey.keyID vCode:apiKey.vCode error:&error];
				if (error) {
					apiKey.error = error;
				}
				else {
					apiKey.apiKeyInfo = apiKeyInfo;
				}
				[pool release];
			}];
			[queue addOperation:operation];
		}
		[queue waitUntilAllOperationsAreFinished];
		[queue release];
		
		for (EVEAccountStorageAPIKey *apiKey in [apiKeys allValues]) {
			if (!apiKey.error) {
				for (EVEAPIKeyInfoCharactersItem *item in apiKey.apiKeyInfo.characters) {
					NSString *key = [NSString stringWithFormat:@"%d", item.characterID];
					EVEAccountStorageCharacter *character = [characters valueForKey:key];
					if (!character) {
						character = [[[EVEAccountStorageCharacter alloc] init] autorelease];
						[characters setValue:character forKey:key];
						character.characterID = item.characterID;
						character.characterName = item.characterName;
						character.corporationID = item.corporationID;
						character.corporationName = item.corporationName;
						character.assignedCharAPIKeys = [[[NSMutableArray alloc] init] autorelease];
						character.assignedCorpAPIKeys = [[[NSMutableArray alloc] init] autorelease];
						character.enabled = ![ignored containsObject:key];
						[character addObserver:self forKeyPath:@"enabled" options: NSKeyValueObservingOptionNew |  NSKeyValueObservingOptionOld context:nil];
					}
					if (apiKey.apiKeyInfo.key.type == EVEAPIKeyTypeCorporation)
						[character.assignedCorpAPIKeys addObject:apiKey];
					else
						[character.assignedCharAPIKeys addObject:apiKey];
					[apiKey.assignedCharacters addObject:character];
				}
			}
		}
	}
}

- (void) save {
	@synchronized(self) {
		if (!apiKeys)
			return;
		NSMutableDictionary *storage = [NSMutableDictionary dictionaryWithObject:[ignored allObjects] forKey:@"ignored"];
		NSMutableArray *accounts = [NSMutableArray array];
		for (EVEAccountStorageAPIKey *apiKey in [apiKeys allValues]) {
			[accounts addObject:[NSDictionary dictionaryWithObjectsAndKeys:
								 [NSNumber numberWithInteger:apiKey.keyID], @"keyID",
								 apiKey.vCode ? apiKey.vCode : @"", @"vCode",
								 nil]];
			
		}
		[storage setValue:accounts forKey:@"apiKeys"];
		[storage writeToURL:[NSURL fileURLWithPath:[Globals accountsFilePath]] atomically:YES];
	}
}

- (BOOL) addAPIKeyWithKeyID:(NSInteger) keyID vCode:(NSString*) vCode error:(NSError**) errorPtr {
	@synchronized(self) {
		if (!apiKeys)
			[self reload];
		
		NSError *error = nil;
		EVEAPIKeyInfo *apiKeyInfo = [EVEAPIKeyInfo apiKeyInfoWithKeyID:keyID vCode:vCode error:&error];
		if (error) {
			if (errorPtr)
				*errorPtr = error;
			return NO;
		}
		else {
			NSString *key = [NSString stringWithFormat:@"%d", keyID];
			EVEAccountStorageAPIKey *apiKey = [apiKeys valueForKey:key];
			if (apiKey) {
				[self removeAPIKey:keyID];
			}
			apiKey = [[[EVEAccountStorageAPIKey alloc] init] autorelease];
			apiKey.keyID = keyID;
			apiKey.vCode = vCode;
			apiKey.apiKeyInfo = apiKeyInfo;
			
			[apiKeys setValue:apiKey forKey:key];
			
			for (EVEAPIKeyInfoCharactersItem *item in apiKey.apiKeyInfo.characters) {
				NSString *key = [NSString stringWithFormat:@"%d", item.characterID];
				EVEAccountStorageCharacter *character = [characters valueForKey:key];
				if (!character) {
					character = [[[EVEAccountStorageCharacter alloc] init] autorelease];
					[characters setValue:character forKey:key];
					character.characterID = item.characterID;
					character.characterName = item.characterName;
					character.corporationID = item.corporationID;
					character.corporationName = item.corporationName;
					character.assignedCharAPIKeys = [[[NSMutableArray alloc] init] autorelease];
					character.assignedCorpAPIKeys = [[[NSMutableArray alloc] init] autorelease];
					character.enabled = ![ignored containsObject:key];
					[character addObserver:self forKeyPath:@"enabled" options: NSKeyValueObservingOptionNew |  NSKeyValueObservingOptionOld context:nil];
				}
				if (apiKey.apiKeyInfo.key.type == EVEAPIKeyTypeCorporation)
					[character.assignedCorpAPIKeys addObject:apiKey];
				else
					[character.assignedCharAPIKeys addObject:apiKey];
				[apiKey.assignedCharacters addObject:character];
			}
		}
		[self save];
	}
	return YES;
}

- (void) removeAPIKey:(NSInteger) keyID {
	@synchronized(self) {
		if (!apiKeys)
			[self reload];
		NSString *key = [NSString stringWithFormat:@"%d", keyID];
		EVEAccountStorageAPIKey *apiKey = [apiKeys valueForKey:key];
		if (apiKey) {
			for (EVEAccountStorageCharacter *character in apiKey.assignedCharacters) {
				if ([character.assignedCharAPIKeys containsObject:apiKey])
					[character.assignedCharAPIKeys removeObject:apiKey];
				else if ([character.assignedCorpAPIKeys containsObject:apiKey])
					[character.assignedCorpAPIKeys removeObject:apiKey];
				if (character.assignedCharAPIKeys.count == 0 && character.assignedCorpAPIKeys.count == 0) {
					[character removeObserver:self forKeyPath:@"enabled"];
					[characters setValue:nil forKey:[NSString stringWithFormat:@"%d", character.characterID]];
				}
			}
			[apiKeys setValue:nil forKey:key];
		}
		[self save];
	}
}

- (NSMutableDictionary*) apiKeys {
	@synchronized(self) {
		if (!apiKeys)
			[self reload];
		return apiKeys;
	}
}

- (NSMutableDictionary*) characters {
	@synchronized(self) {
		if (!characters)
			[self reload];
		return characters;
	}
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	BOOL oldValue = [[change valueForKey:NSKeyValueChangeOldKey] boolValue];
	BOOL newValue = [[change valueForKey:NSKeyValueChangeNewKey] boolValue];
	if (oldValue == newValue)
		return;
	NSString *key = [NSString stringWithFormat:@"%d", [object characterID]];
	if (oldValue == NO && newValue == YES) {
		[ignored removeObject:key];
	}
	else if (oldValue == YES && newValue == NO) {
		[ignored addObject:key];
	}
	[self save];
}

@end
