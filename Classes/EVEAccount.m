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
@synthesize charKeyID;
@synthesize charVCode;
@synthesize charAccessMask;
@synthesize corpKeyID;
@synthesize corpVCode;
@synthesize corpAccessMask;

@synthesize characterID;
@synthesize characterName;
@synthesize corporationID;
@synthesize corporationName;

@synthesize characterSheet;
@synthesize skillQueue;
@synthesize properties;
@synthesize skillPlan;
@synthesize mailBox;

@synthesize characterAttributes;

- (id) init {
	if (self = [super init]) {
		self.properties = [NSMutableDictionary dictionary];
	}
	return self;
}

+ (EVEAccount*) accountWithCharacter:(EVEAccountStorageCharacter*) character {
	if (!character)
		return nil;
	return [[[EVEAccount alloc] initWithCharacter:character] autorelease];
}

+ (EVEAccount*) accountWithDictionary:(NSDictionary*) dictionary {
	if (!dictionary)
		return nil;
	return [[[EVEAccount alloc] initWithDictionary:dictionary] autorelease];
}

+ (EVEAccount*) dummyAccount {
	EVEAccount *account = [[[EVEAccount alloc] init] autorelease];
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
	[charVCode release];
	[corpVCode release];
	[characterName release];
	[corporationName release];
	[characterSheet release];
	[skillQueue release];
	[properties release];

	[skillPlan save];
	[skillPlan release];
	[mailBox release];
	[characterAttributes release];
	[super dealloc];
}

+ (EVEAccount*) currentAccount {
	EVEUniverseAppDelegate *delegate = (EVEUniverseAppDelegate*) [[UIApplication sharedApplication] delegate];
	return [[delegate.currentAccount retain] autorelease];
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
	return [NSDictionary dictionaryWithObjectsAndKeys:
			[NSNumber numberWithInteger:charKeyID], @"charKeyID",
			charVCode ? charVCode : @"", @"charVCode",
			[NSNumber numberWithInteger:charAccessMask], @"charAccessMask",
			[NSNumber numberWithInteger:corpKeyID], @"corpKeyID",
			corpVCode ? corpVCode : @"", @"corpVCode",
			[NSNumber numberWithInteger:corpAccessMask], @"corpAccessMask",
			[NSNumber numberWithInteger:characterID], @"characterID",
			characterName ? characterName : @"", @"characterName",
			[NSNumber numberWithInteger:corporationID], @"corporationID",
			corporationName ? corporationName : @"", @"corporationName",
			nil];
}

- (void) updateSkillpoints {
	if (!self.characterSheet || !self.skillQueue)
		return;
	NSDate *currentTime = [skillQueue serverTimeWithLocalTime:[NSDate date]];
	for (EVESkillQueueItem *item in skillQueue.skillQueue) {
		for (EVECharacterSheetSkill *skill in characterSheet.skills) {
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
		if (!characterSheet) {
			NSError *error = nil;
			if (!self.charKeyID || !self.charVCode || !self.characterID)
				return nil;
			[characterSheet release];
			self.characterSheet = [EVECharacterSheet characterSheetWithKeyID:charKeyID vCode:charVCode characterID:characterID error:&error];
		}
		return [[characterSheet retain] autorelease];
	}
}

- (void) setCharacterSheet:(EVECharacterSheet *) value {
	@synchronized(self) {
		[value retain];
		[characterSheet release];
		characterSheet = value;
		
		self.characterAttributes = [CharacterAttributes defaultCharacterAttributes];
		if (characterSheet) {
			characterAttributes.charisma = characterSheet.attributes.charisma;
			characterAttributes.intelligence = characterSheet.attributes.intelligence;
			characterAttributes.memory = characterSheet.attributes.memory;
			characterAttributes.perception = characterSheet.attributes.perception;
			characterAttributes.willpower = characterSheet.attributes.willpower;
			
			for (EVECharacterSheetAttributeEnhancer *enhancer in characterSheet.attributeEnhancers) {
				switch (enhancer.attribute) {
					case EVECharacterAttributeCharisma:
						characterAttributes.charisma += enhancer.augmentatorValue;
						break;
					case EVECharacterAttributeIntelligence:
						characterAttributes.intelligence += enhancer.augmentatorValue;
						break;
					case EVECharacterAttributeMemory:
						characterAttributes.memory += enhancer.augmentatorValue;
						break;
					case EVECharacterAttributePerception:
						characterAttributes.perception += enhancer.augmentatorValue;
						break;
					case EVECharacterAttributeWillpower:
						characterAttributes.willpower += enhancer.augmentatorValue;
						break;
				}
			}
			[self updateSkillpoints];
		}
	}
}

- (CharacterAttributes*) characterAttributes {
	if (!characterAttributes)
		characterAttributes = [[CharacterAttributes defaultCharacterAttributes] retain];
	return characterAttributes;
}

- (EVESkillQueue*) skillQueue {
	@synchronized(self) {
		if (!skillQueue) {
			NSError *error = nil;
			if (!self.charKeyID || !self.charVCode || !self.characterID)
				return nil;
			//self.skillQueue = [EVESkillQueue skillQueueWithUserID:self.userID apiKey:self.apiKey characterID:self.characterID error:&error];
			self.skillQueue = [EVESkillQueue skillQueueWithKeyID:charKeyID vCode:charVCode characterID:characterID error:&error];
		}
		return skillQueue;
	}
}

- (void) setSkillQueue:(EVESkillQueue *) value {
	@synchronized(self) {
		[value retain];
		[skillQueue release];
		skillQueue = value;
		if (skillQueue)
			[self updateSkillpoints];
	}
}

- (SkillPlan*) skillPlan {
	@synchronized(self) {
		if (!skillPlan) {
			if (!self.characterID || !self.characterSheet)
				return nil;
			skillPlan = [[SkillPlan skillPlanWithAccount:self] retain];
			[skillPlan load];
		}
		return [[skillPlan retain] autorelease];
	}
}

- (void) setSkillPlan:(SkillPlan *)value {
	@synchronized(self) {
		[value retain];
		[skillPlan release];
		skillPlan = value;
	}
}

- (EUMailBox*) mailBox {
	@synchronized(self) {
		if (!mailBox) {
			if (!self.charKeyID || !self.charVCode)
				return nil;
			mailBox = [[EUMailBox alloc] initWithAccount:self];
			[mailBox inbox];
		}
		return [[mailBox retain] autorelease];
	}
}

- (void) setMailBox:(EUMailBox *)value {
	@synchronized(self) {
		[value retain];
		[mailBox release];
		mailBox = value;
	}
}

@end