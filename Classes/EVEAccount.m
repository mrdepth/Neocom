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

+ (EVEAccount*) accountWithCharacter:(EVEAccountStorageCharacter*) character {
	if (!character)
		return nil;
	return [[EVEAccount alloc] initWithCharacter:character];
}

+ (EVEAccount*) accountWithDictionary:(NSDictionary*) dictionary {
	if (!dictionary)
		return nil;
	return [[EVEAccount alloc] initWithDictionary:dictionary];
}

+ (EVEAccount*) dummyAccount {
	EVEAccount *account = [[EVEAccount alloc] init];
	return account;
}

- (id) initWithDictionary:(NSDictionary*) dictionary {
	if (self = [self init]) {
		self.charKeyID = [[dictionary valueForKey:@"charKeyID"] integerValue];
		self.charVCode = [dictionary valueForKey:@"charVCode"];
		self.charAccessMask = [[dictionary valueForKey:@"charAccessMask"] integerValue];
		self.corpKeyID = [[dictionary valueForKey:@"corpKeyID"] integerValue];
		self.corpVCode = [dictionary valueForKey:@"corpVCode"];
		self.corpAccessMask = [[dictionary valueForKey:@"corpAccessMask"] integerValue];
		
		self.characterID = [[dictionary valueForKey:@"characterID"] integerValue];
		self.characterName = [dictionary valueForKey:@"characterName"];
		self.corporationID = [[dictionary valueForKey:@"corporationID"] integerValue];
		self.corporationName = [dictionary valueForKey:@"corporationName"];
	}
	return self;
}

- (id) initWithCharacter:(EVEAccountStorageCharacter*) character {
	if (self = [self init]) {
		self.characterID = character.characterID;
		self.characterName = character.characterName;
		self.corporationID = character.corporationID;
		self.corporationName = character.corporationName;
		
		EVEAccountStorageAPIKey *charAPIKey = character.anyCharAPIKey;
		EVEAccountStorageAPIKey *corpAPIKey = character.anyCorpAPIKey;
		
		if (corpAPIKey) {
			self.corpKeyID = corpAPIKey.keyID;
			self.corpVCode = corpAPIKey.vCode;
			self.corpAccessMask = corpAPIKey.apiKeyInfo.key.accessMask;
		}
		if (charAPIKey) {
			self.charKeyID = charAPIKey.keyID;
			self.charVCode = charAPIKey.vCode;
			self.charAccessMask = charAPIKey.apiKeyInfo.key.accessMask;
		}
	}
	return self;
}

- (void) dealloc {
	[self.skillPlan save];
}

+ (EVEAccount*) currentAccount {
	EVEUniverseAppDelegate *delegate = (EVEUniverseAppDelegate*) [[UIApplication sharedApplication] delegate];
	return delegate.currentAccount;
}

- (void) login {
	EVEUniverseAppDelegate *delegate = (EVEUniverseAppDelegate*) [[UIApplication sharedApplication] delegate];
	delegate.currentAccount = self;
}

- (void) logoff {
	EVEUniverseAppDelegate *delegate = (EVEUniverseAppDelegate*) [[UIApplication sharedApplication] delegate];
	delegate.currentAccount = nil;
}

+ (void) reload {
	EVEUniverseAppDelegate *delegate = (EVEUniverseAppDelegate*) [[UIApplication sharedApplication] delegate];
	delegate.currentAccount = [EVEAccount currentAccount];
}


- (NSDictionary*) dictionary {
	return @{@"charKeyID": @(self.charKeyID),
		  @"charVCode": self.charVCode ? self.charVCode : @"",
		  @"charAccessMask": @(self.charAccessMask),
		  @"corpKeyID": @(self.corpKeyID),
		  @"corpVCode": self.corpVCode ? self.corpVCode : @"",
		  @"corpAccessMask": @(self.corpAccessMask),
		  @"characterID": @(self.characterID),
		  @"characterName": self.characterName ? self.characterName : @"",
		  @"corporationID": @(self.corporationID),
		  @"corporationName": self.corporationName ? self.corporationName : @"",
		  };
}

- (void) updateSkillpoints {
	if (!self.characterSheet || !self.skillQueue)
		return;
	NSDate *currentTime = [self.skillQueue serverTimeWithLocalTime:[NSDate date]];
	for (EVESkillQueueItem *item in self.skillQueue.skillQueue) {
		for (EVECharacterSheetSkill *skill in self.characterSheet.skills) {
			if (skill.typeID == item.typeID && item.endTime && item.startTime) {
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
			NSError *error = nil;
			if (!self.charKeyID || !self.charVCode || !self.characterID)
				return nil;
			_characterSheet = [EVECharacterSheet characterSheetWithKeyID:self.charKeyID vCode:self.charVCode characterID:self.characterID error:&error progressHandler:nil];
		}
		return _characterSheet;
	}
}

- (void) setCharacterSheet:(EVECharacterSheet *) value {
	@synchronized(self) {
		_characterSheet = value;
		
		_characterAttributes = [CharacterAttributes defaultCharacterAttributes];
		if (_characterSheet) {
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
			NSError *error = nil;
			if (!self.charKeyID || !self.charVCode || !self.characterID)
				return nil;
			_skillQueue = [EVESkillQueue skillQueueWithKeyID:self.charKeyID vCode:self.charVCode characterID:self.characterID error:&error progressHandler:nil];
		}
		return _skillQueue;
	}
}

- (void) setSkillQueue:(EVESkillQueue *) value {
	@synchronized(self) {
		_skillQueue = value;
		if (_skillQueue)
			[self updateSkillpoints];
	}
}

- (SkillPlan*) skillPlan {
	@synchronized(self) {
		if (!_skillPlan) {
			if (!self.characterID || !self.characterSheet)
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
			if (!self.charKeyID || !self.charVCode)
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

@end