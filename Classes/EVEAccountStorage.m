//
//  EVEAccountStorage.m
//  EVEUniverse
//
//  Created by Shimanski on 8/31/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "EVEAccountStorage.h"
#import "Globals.h"
#import "EUStorage.h"
#import "APIKey.h"
#import "IgnoredCharacter.h"

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
		ignored = [[NSMutableDictionary alloc] init];
		
		
		EUStorage* storage = [EUStorage sharedStorage];
		
		[[storage managedObjectContext] performBlockAndWait:^{
			NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
			NSEntityDescription *entity = [NSEntityDescription entityForName:@"IgnoredCharacter" inManagedObjectContext:storage.managedObjectContext];
			[fetchRequest setEntity:entity];
			
			NSArray *fetchedObjects = [storage.managedObjectContext executeFetchRequest:fetchRequest error:nil];
			[fetchRequest release];
			for (IgnoredCharacter* character in fetchedObjects) {
				NSString* key = [NSString stringWithFormat:@"%d", character.characterID];
				[ignored setValue:character forKey:key];
			}
			
			
			fetchRequest = [[NSFetchRequest alloc] init];
			entity = [NSEntityDescription entityForName:@"APIKey" inManagedObjectContext:storage.managedObjectContext];
			[fetchRequest setEntity:entity];
			
			NSError *error = nil;
			fetchedObjects = [storage.managedObjectContext executeFetchRequest:fetchRequest error:&error];
			[fetchRequest release];
			
			NSOperationQueue *queue = [[NSOperationQueue alloc] init];
			for (APIKey *apiKey in fetchedObjects) {
				apiKey.assignedCharacters = [NSMutableArray array];
				apiKey.error = nil;
				apiKey.apiKeyInfo = nil;
				
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
			
			for (APIKey *apiKey in [apiKeys allValues]) {
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
							character.enabled = ![ignored valueForKey:key];
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
		}];
	}
}

- (void) save {
	@synchronized(self) {
		if (!apiKeys)
			return;
		[[EUStorage sharedStorage] saveContext];
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
			__block APIKey *apiKey = [apiKeys valueForKey:key];
			if (apiKey) {
				//[self removeAPIKey:keyID];
				apiKey.vCode = vCode;
			}
			else {
				EUStorage* storage = [EUStorage sharedStorage];
				[storage.managedObjectContext performBlockAndWait:^{
					apiKey = [[APIKey alloc] initWithEntity:[NSEntityDescription entityForName:@"APIKey" inManagedObjectContext:storage.managedObjectContext]
							  insertIntoManagedObjectContext:storage.managedObjectContext];
					apiKey.keyID = keyID;
					apiKey.vCode = vCode;
					apiKey.apiKeyInfo = apiKeyInfo;
					[apiKeys setValue:apiKey forKey:key];
				}];
				[apiKey autorelease];
			}
			
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
					character.enabled = ![ignored valueForKey:key];
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
		APIKey *apiKey = [apiKeys valueForKey:key];
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
			EUStorage* storage = [EUStorage sharedStorage];
			[storage.managedObjectContext performBlockAndWait:^{
				[storage.managedObjectContext deleteObject:apiKey];
			}];
		}
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
	EUStorage* storage = [EUStorage sharedStorage];
	if (oldValue == NO && newValue == YES) {
		IgnoredCharacter* character = [ignored valueForKey:key];
		if (character) {
			[storage.managedObjectContext deleteObject:character];
		}
		[ignored removeObjectForKey:key];
	}
	else if (oldValue == YES && newValue == NO) {
		IgnoredCharacter* character = [[[IgnoredCharacter alloc] initWithEntity:[NSEntityDescription entityForName:@"IgnoredCharacter" inManagedObjectContext:storage.managedObjectContext]
												 insertIntoManagedObjectContext:storage.managedObjectContext] autorelease];
		character.characterID = [object characterID];
		[ignored setValue:character forKey:key];
	}
	[self save];
}

@end
