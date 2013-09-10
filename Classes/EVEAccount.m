//
//  EVEAccount.m
//  EVEUniverse
//
//  Created by Artem Shimanski on 9/2/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "EVEAccount.h"
#import "EVEUniverseAppDelegate.h"
#import "EVEOnlineAPI.h"
#import "EUStorage.h"
#import "APIKey.h"
#import "IgnoredCharacter.h"
#import "Globals.h"

static EVEAccount* currentAccount;

@interface EVEAccount()

- (void) loadCharacterSheet;
- (void) loadSkillQueue;
- (void) loadAccountStatus;
- (void) loadCharacterInfo;
- (void) loadAccountBalance;
- (void) loadCharAPIKey;
- (void) loadCorpAPIKey;

@end

@implementation EVEAccount
@synthesize characterSheet = _characterSheet;
@synthesize skillQueue = _skillQueue;
@synthesize skillPlan = _skillPlan;
@synthesize mailBox = _mailBox;

- (id) init {
	if (self = [super init]) {
		self.properties = [NSMutableDictionary dictionary];
	}
	return self;
}

+ (EVEAccount*) dummyAccount {
	EVEAccount *account = [[EVEAccount alloc] init];
	return account;
}

- (void) dealloc {
	[self.skillPlan save];
}

+ (EVEAccount*) currentAccount {
	return currentAccount;
	//EVEUniverseAppDelegate *delegate = (EVEUniverseAppDelegate*) [[UIApplication sharedApplication] delegate];
	//return delegate.currentAccount;
}

+ (void) setCurrentAccount:(EVEAccount *)account {
	currentAccount = account;
	[[NSNotificationCenter defaultCenter] postNotificationName:EVEAccountDidSelectNotification object:currentAccount];
}

- (void) login {
	EVEUniverseAppDelegate *delegate = (EVEUniverseAppDelegate*) [[UIApplication sharedApplication] delegate];
	delegate.currentAccount = self;
}

- (void) logoff {
	EVEUniverseAppDelegate *delegate = (EVEUniverseAppDelegate*) [[UIApplication sharedApplication] delegate];
	delegate.currentAccount = nil;
}

- (void) reload {
/*	self.characterSheet = nil;
	self.skillQueue = nil;
	self.characterInfo = nil;
	self.accountStatus = nil;
	self.mailBox = nil;
	self.accountBalance = nil;*/
	//[self characterSheet];
/*	[self skillQueue];
	[self characterInfo];
	[self accountStatus];
	[self accountBalance];*/
	
	self.mailBox = nil;
	[self loadCharAPIKey];
	[self loadCorpAPIKey];
	[self loadSkillQueue];
	[self loadCharacterInfo];
	[self loadCharacterSheet];
	[self loadAccountStatus];
	[self loadAccountBalance];
	
	if ([NSThread isMainThread])
		[[NSNotificationCenter defaultCenter] postNotificationName:EVEAccountDidUpdateNotification object:self];
	else
		dispatch_async(dispatch_get_main_queue(), ^{
			[[NSNotificationCenter defaultCenter] postNotificationName:EVEAccountDidUpdateNotification object:self];
		});
}


- (NSDictionary*) dictionary {
	return @{};
}

- (void) updateSkillpoints {
	@synchronized(self) {
		if (!self.characterSheet || !self.skillQueue)
			return;
		NSDate *currentTime = [self.skillQueue serverTimeWithLocalTime:[NSDate date]];
		for (EVESkillQueueItem *item in self.skillQueue.skillQueue) {
			if (item.endTime && item.startTime) {
				EVECharacterSheetSkill *skill = self.characterSheet.skillsMap[@(item.typeID)];
				if (item.queuePosition == 0) {
					EVEDBInvType *type = [EVEDBInvType invTypeWithTypeID:item.typeID error:nil];
					skill.skillpoints = item.endSP - [item.endTime timeIntervalSinceDate:currentTime] * [self.characterAttributes skillpointsPerSecondForSkill:type];
				}
				else if (item.level - 1 == skill.level) {
					EVEDBInvType *type = [EVEDBInvType invTypeWithTypeID:item.typeID error:nil];
					skill.skillpoints = item.endSP - [item.endTime timeIntervalSinceDate:item.startTime] * [self.characterAttributes skillpointsPerSecondForSkill:type];
				}
			}
		}
	}
}

- (EVECharacterSheet*) characterSheet {
	@synchronized(self) {
		if (!_characterSheet) {
			[self loadCharacterSheet];
		}
		if ([_characterSheet isKindOfClass:[EVECharacterSheet class]])
			return _characterSheet;
		else
			return nil;
	}
}

- (void) setCharacterSheet:(EVECharacterSheet *) value {
	@synchronized(self) {
		_characterSheet = value;
		
		_characterAttributes = [CharacterAttributes defaultCharacterAttributes];
		if ([_characterSheet isKindOfClass:[EVECharacterSheet class]]) {
			_characterAttributes.charisma = _characterSheet.attributes.charisma;
			_characterAttributes.intelligence = _characterSheet.attributes.intelligence;
			_characterAttributes.memory = _characterSheet.attributes.memory;
			_characterAttributes.perception = _characterSheet.attributes.perception;
			_characterAttributes.willpower = _characterSheet.attributes.willpower;
			
			for (EVECharacterSheetAttributeEnhancer *enhancer in _characterSheet.attributeEnhancers) {
				switch (enhancer.attribute) {
					case EVECharacterAttributeCharisma:
						_characterAttributes.charisma += enhancer.augmentatorValue;
						break;
					case EVECharacterAttributeIntelligence:
						_characterAttributes.intelligence += enhancer.augmentatorValue;
						break;
					case EVECharacterAttributeMemory:
						_characterAttributes.memory += enhancer.augmentatorValue;
						break;
					case EVECharacterAttributePerception:
						_characterAttributes.perception += enhancer.augmentatorValue;
						break;
					case EVECharacterAttributeWillpower:
						_characterAttributes.willpower += enhancer.augmentatorValue;
						break;
				}
			}
			[self updateSkillpoints];
		}
	}
}

- (CharacterAttributes*) characterAttributes {
	if (!_characterAttributes)
		_characterAttributes = [CharacterAttributes defaultCharacterAttributes];
	return _characterAttributes;
}

- (EVESkillQueue*) skillQueue {
	@synchronized(self) {
		if (!_skillQueue) {
			[self loadSkillQueue];
		}
		if ([_skillQueue isKindOfClass:[EVESkillQueue class]])
			return _skillQueue;
		else
			return nil;
	}
}

- (SkillPlan*) skillPlan {
	@synchronized(self) {
		if (!_skillPlan) {
			if (!self.character || !self.characterSheet)
				return nil;
			_skillPlan = [SkillPlan skillPlanWithAccount:self name:@"main"];
			[_skillPlan load];
		}
		return _skillPlan;
	}
}

- (void) setSkillPlan:(SkillPlan *)value {
	@synchronized(self) {
		_skillPlan = value;
	}
}

- (EUMailBox*) mailBox {
	@synchronized(self) {
		if (!_mailBox) {
			if (!self.charAPIKey)
				return nil;
			_mailBox = [[EUMailBox alloc] initWithAccount:self];
			[_mailBox inbox];
		}
		return _mailBox;
	}
}

- (void) setMailBox:(EUMailBox *)value {
	@synchronized(self) {
		_mailBox = value;
	}
}

- (EVEAccountStatus*) accountStatus {
	@synchronized(self) {
		if (!_accountStatus && self.charAPIKey) {
			[self loadAccountStatus];
		}
		if ([_accountStatus isKindOfClass:[EVEAccountStatus class]])
			return _accountStatus;
		else
			return nil;
		
	}
}

- (EVECharacterInfo*) characterInfo {
	@synchronized(self) {
		if (!_characterInfo && self.charAPIKey) {
			[self loadCharacterInfo];
		}
		if ([_characterInfo isKindOfClass:[EVECharacterInfo class]])
			return _characterInfo;
		else
			return nil;
		
	}
}

- (EVEAccountBalance*) accountBalance {
	@synchronized(self) {
		if (!_accountBalance && self.charAPIKey) {
			[self loadAccountBalance];
		}
		if ([_accountBalance isKindOfClass:[EVEAccountBalance class]])
			return _accountBalance;
		else
			return nil;
		
	}
}

- (APIKey*) charAPIKey {
	@synchronized(self) {
		if (!_charAPIKey) {
			[self loadCharAPIKey];
		}
		return _charAPIKey;
	}
}

- (APIKey*) corpAPIKey {
	@synchronized(self) {
		if (!_corpAPIKey) {
			[self loadCorpAPIKey];
		}
		return _corpAPIKey;
	}
}

#pragma mark - Private

- (void) loadCharacterSheet {
	NSError *error = nil;
	if (!self.charAPIKey)
		return;
	EVECharacterSheet* characterSheet = [EVECharacterSheet characterSheetWithKeyID:self.charAPIKey.keyID vCode:self.charAPIKey.vCode characterID:self.character.characterID error:&error progressHandler:nil];
	if (!characterSheet)
		characterSheet = (EVECharacterSheet*) [NSNull null];
	@synchronized(self) {
		self.characterSheet = characterSheet;
	}
}

- (void) loadSkillQueue {
	NSError *error = nil;
	if (!self.charAPIKey)
		return;
	EVESkillQueue* skillQueue = [EVESkillQueue skillQueueWithKeyID:self.charAPIKey.keyID vCode:self.charAPIKey.vCode characterID:self.character.characterID error:&error progressHandler:nil];
	if (!skillQueue)
		skillQueue = (EVESkillQueue*) [NSNull null];
	@synchronized(self) {
		self.skillQueue = skillQueue;
	}
}

- (void) loadAccountStatus {
	NSError *error = nil;
	if (!self.charAPIKey)
		return;
	EVEAccountStatus* accountStatus = [EVEAccountStatus accountStatusWithKeyID:self.charAPIKey.keyID vCode:self.charAPIKey.vCode error:&error progressHandler:nil];
	if (!accountStatus)
		accountStatus = (EVEAccountStatus*) [NSNull null];
	@synchronized(self) {
		self.accountStatus = accountStatus;
	}
}

- (void) loadCharacterInfo {
	NSError *error = nil;
	if (!self.charAPIKey)
		return;
	EVECharacterInfo* characterInfo = [EVECharacterInfo characterInfoWithKeyID:self.charAPIKey.keyID vCode:self.charAPIKey.vCode characterID:self.character.characterID error:&error progressHandler:nil];
	if (!characterInfo)
		characterInfo = (EVECharacterInfo*) [NSNull null];
	@synchronized(self) {
		self.characterInfo = characterInfo;
	}
}

- (void) loadAccountBalance {
	NSError *error = nil;
	if (!self.charAPIKey)
		return;
	EVEAccountBalance* accountBalance = [EVEAccountBalance accountBalanceWithKeyID:self.charAPIKey.keyID vCode:self.charAPIKey.vCode characterID:self.character.characterID corporate:NO error:&error progressHandler:nil];
	if (!accountBalance)
		accountBalance = (EVEAccountBalance*) [NSNull null];
	@synchronized(self) {
		self.accountBalance = accountBalance;
	}
}

- (void) loadCharAPIKey {
	APIKey* charAPIKey = nil;
	for (APIKey* apiKey in self.apiKeys)
		if (apiKey.apiKeyInfo.key.type != EVEAPIKeyTypeCorporation) {
			charAPIKey = apiKey;
			break;
		}

	@synchronized(self) {
		self.charAPIKey = charAPIKey;
	}
}

- (void) loadCorpAPIKey {
	APIKey* corpAPIKey = nil;
	for (APIKey* apiKey in self.apiKeys)
		if (apiKey.apiKeyInfo.key.type == EVEAPIKeyTypeCorporation) {
			corpAPIKey = apiKey;
			break;
		}
	
	@synchronized(self) {
		self.corpAPIKey = corpAPIKey;
	}
}

@end