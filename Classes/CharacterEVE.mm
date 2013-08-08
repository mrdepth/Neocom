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
#import "EVEAccountsManager.h"

@interface CharacterEVE()
@property (nonatomic, strong) EVEAccount* account;

@end

@implementation CharacterEVE

+ (id) characterWithCharacter:(EVEAccountStorageCharacter*) character {
	return [[CharacterEVE alloc] initWithCharacter:character];
}

+ (id) characterWithCharacterID:(NSInteger) characterID keyID:(NSInteger) keyID vCode:(NSString*) vCode name:(NSString*) name {
	return [[CharacterEVE alloc] initWithCharacterID:characterID keyID:keyID vCode:vCode name:name];
}

+ (id) characterWithAccount:(EVEAccount*) account {
	return [[CharacterEVE alloc] initWithAccount:account];
}

- (id) initWithCharacter:(EVEAccountStorageCharacter*) character {
	if (self = [super init]) {
		return nil;
	}
	return self;
}

- (id) initWithCharacterID:(NSInteger) characterID keyID:(NSInteger) keyID vCode:(NSString*) vCode name:(NSString*) name {
	if (self = [super init]) {
		return nil;
	}
	return self;
}

- (id) initWithAccount:(EVEAccount*) account {
	if (self = [super init]) {
		if (account.charAPIKey) {
			self.account = account;
			self.name = account.character.characterName;
			self.characterID = account.character.characterID;
		}
		else {
			return nil;
		}
	}
	return self;
}

- (NSMutableDictionary*) skills {
	NSMutableDictionary* skills = [super skills];
	if (!skills) {
		NSError* error = nil;
		EVECharacterSheet* characterSheet = [EVECharacterSheet characterSheetWithKeyID:self.account.charAPIKey.keyID vCode:self.account.charAPIKey.vCode characterID:self.characterID error:&error progressHandler:nil];
		
		if (error) {
			Character* cachedCharacter = [NSKeyedUnarchiver unarchiveObjectWithFile:[[[Character charactersDirectory] stringByAppendingPathComponent:self.guid] stringByAppendingPathExtension:@"plist"]];
			if (cachedCharacter)
				skills = cachedCharacter.skills;
			else {
				skills = (NSMutableDictionary*) [NSNull null];
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
		self.skills = skills;
	}
	return skills != (NSMutableDictionary*) [NSNull null] ? skills : nil;
}

- (NSString*) guid {
	return [NSString stringWithFormat:@"e%d", self.characterID];
}

@end
