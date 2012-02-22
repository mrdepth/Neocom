//
//  CharacterEVE.m
//  EVEUniverse
//
//  Created by Mr. Depth on 12/21/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "CharacterEVE.h"
#import "EVEAccountStorageCharacter.h"
#import "EVEAccountStorageAPIKey.h"
#import "EVEOnlineAPI.h"
#import "UIAlertView+Error.h"

@implementation CharacterEVE

+ (id) characterWithCharacter:(EVEAccountStorageCharacter*) character {
	return [[[CharacterEVE alloc] initWithCharacter:character] autorelease];
}

+ (id) characterWithCharacterID:(NSInteger) characterID keyID:(NSInteger) keyID vCode:(NSString*) vCode name:(NSString*) name {
	return [[[CharacterEVE alloc] initWithCharacterID:characterID keyID:keyID vCode:vCode name:name] autorelease];
}

- (id) initWithCharacter:(EVEAccountStorageCharacter*) character {
	if (self = [super init]) {
		if (character && character.assignedCharAPIKeys.count > 0) {
			EVEAccountStorageAPIKey* apiKey = [character.assignedCharAPIKeys objectAtIndex:0];
			name = [character.characterName copy];
			characterID = character.characterID;
			keyID = apiKey.keyID;
			vCode = [apiKey.vCode copy];
		}
		else {
			[self release];
			return nil;
		}
	}
	return self;
}

- (id) initWithCharacterID:(NSInteger) aCharacterID keyID:(NSInteger) aKeyID vCode:(NSString*) aVCode name:(NSString*) aName {
	if (self = [super init]) {
		if (!aCharacterID || !aKeyID || !aKeyID) {
			[self release];
			return nil;
		}
		else {
			characterID = aCharacterID;
			keyID = aKeyID;
			vCode = [aVCode copy];
			name = [aName copy];
		}
	}
	return self;
}

- (NSMutableDictionary*) skills {
	if (!skills) {
		NSError* error = nil;
		EVECharacterSheet* characterSheet = [EVECharacterSheet characterSheetWithKeyID:keyID vCode:vCode characterID:characterID error:&error];
		
		if (error) {
			Character* cachedCharacter = [NSKeyedUnarchiver unarchiveObjectWithFile:[[[Character charactersDirectory] stringByAppendingPathComponent:self.guid] stringByAppendingPathExtension:@"plist"]];
			if (cachedCharacter)
				skills = [cachedCharacter.skills retain];
			else {
				skills = (NSMutableDictionary*) [[NSNull null] retain];
				[[NSOperationQueue mainQueue] addOperationWithBlock:^{
					[[UIAlertView alertViewWithError:error] show];
				}];
			}
		}
		else {
			skills = [[NSMutableDictionary alloc] init];
			for (EVECharacterSheetSkill* skill in characterSheet.skills)
				[skills setValue:[NSNumber numberWithInteger:skill.level] forKey:[NSString stringWithFormat:@"%d", skill.typeID]];
		}
	}
	return skills != (NSMutableDictionary*) [NSNull null] ? skills : nil;
}

- (void) dealloc {
	[vCode release];
	[super dealloc];
}

- (NSString*) guid {
	return [NSString stringWithFormat:@"e%d", characterID];
}

@end
