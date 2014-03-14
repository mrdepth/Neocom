//
//  NCCharacterID.m
//  Neocom
//
//  Created by Артем Шиманский on 27.02.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCCharacterID.h"
#import "EVEOnlineAPI.h"
#import "NCCache.h"

@interface NCCharacterID()<NSCoding>
@property (nonatomic, assign, readwrite) NCCharacterIDType type;
@property (nonatomic, assign, readwrite) int32_t characterID;
@property (nonatomic, strong, readwrite) NSString* name;
@end

@implementation NCCharacterID

+ (id) characterIDWithName:(NSString*) name {
	name = [name lowercaseString];
	NCCache* cache = [NCCache sharedCache];
	__block NCCacheRecord* cacheRecord = nil;
	__block NSMutableDictionary* nameToCharacterID = nil;
	__block NCCacheRecord* alliancesCacheRecord = nil;
	__block NSMutableDictionary* alliances = nil;
	
	[cache.managedObjectContext performBlockAndWait:^{
		cacheRecord = [NCCacheRecord cacheRecordWithRecordID:@"NCCharacterID"];
		alliancesCacheRecord = [NCCacheRecord cacheRecordWithRecordID:@"NCCharacterID.alliances"];
		if ([cacheRecord.expireDate compare:[NSDate date]] == NSOrderedDescending)
			nameToCharacterID = [cacheRecord.data.data mutableCopy];

		if ([alliancesCacheRecord.expireDate compare:[NSDate date]] == NSOrderedDescending)
			alliances = [alliancesCacheRecord.data.data mutableCopy];
	}];
	
	if (!nameToCharacterID) {
		nameToCharacterID = [NSMutableDictionary new];
		cacheRecord.date = [NSDate date];
		cacheRecord.expireDate = [NSDate dateWithTimeIntervalSinceNow:60 * 60 * 24 * 2];
	}
		
	NCCharacterID* characterID = nameToCharacterID[name];
	
	if (!characterID && alliances)
		characterID = alliances[name];
	
	if (!characterID && ![NSThread isMainThread]) {
		EVECharacterID* charID = [EVECharacterID characterIDWithNames:@[name] cachePolicy:NSURLRequestUseProtocolCachePolicy error:nil progressHandler:nil];
		if (!charID || charID.characters.count == 0)
			return nil;
		int32_t identifier = [charID.characters[0] characterID];
		if (identifier == 0)
			return nil;
		
		EVECharacterInfo* characterInfo = [EVECharacterInfo characterInfoWithKeyID:0
																			 vCode:nil
																	   cachePolicy:NSURLRequestUseProtocolCachePolicy
																	   characterID:identifier
																			 error:nil
																   progressHandler:nil];
		if (characterInfo) {
			characterID = [NCCharacterID new];
			characterID.characterID = characterInfo.characterID;
			characterID.type = NCCharacterIDTypeCharacter;
			characterID.name = characterInfo.characterName;
			nameToCharacterID[name] = characterID;
		}
		else {
			if (!alliances) {
				alliances = [NSMutableDictionary new];
				EVEAllianceList *allianceList = [EVEAllianceList allianceListWithCachePolicy:NSURLRequestUseProtocolCachePolicy
																					   error:nil
																			 progressHandler:nil];
				if (allianceList) {
					for (EVEAllianceListItem* alliance in allianceList.alliances) {
						NCCharacterID* record = [NCCharacterID new];
						record.characterID = alliance.allianceID;
						record.type = NCCharacterIDTypeAlliance;
						record.name = alliance.name;
						alliances[[alliance.name lowercaseString]] = record;
						if (alliance.allianceID == identifier)
							characterID = record;
					}
					alliancesCacheRecord.date = allianceList.currentServerTime;
					alliancesCacheRecord.expireDate = [[NSDate dateWithTimeIntervalSinceNow:60 * 60 * 24 * 2] laterDate:allianceList.cacheExpireDate];
				}
			}
			if (!characterID) {
				EVECharacterName* charName = [EVECharacterName characterNameWithIDs:@[@(identifier)]
																	cachePolicy:NSURLRequestUseProtocolCachePolicy
																		  error:nil
																progressHandler:nil];
				characterID = [NCCharacterID new];
				characterID.characterID = identifier;
				characterID.type = NCCharacterIDTypeCorporation;
				characterID.name = charName.characters[@(identifier)];
				nameToCharacterID[name] = characterID;
			}
		}
	}
	
	[cache.managedObjectContext performBlockAndWait:^{
		if (![alliances isEqualToDictionary:alliancesCacheRecord.data.data])
			alliancesCacheRecord.data.data = alliances;
		if (![nameToCharacterID isEqualToDictionary:cacheRecord.data.data])
			cacheRecord.data.data = nameToCharacterID;
		[cache saveContext];
	}];
	
	return characterID;
}

- (BOOL) isEqual:(id)object {
	if ([object isKindOfClass:self.class] && self.characterID == [object characterID])
		return YES;
	else
		return NO;
}

- (NSUInteger) hash {
	return self.characterID;
}

#pragma mark - NSCoding

- (id) initWithCoder:(NSCoder *)aDecoder {
	if (self = [super init]) {
		self.name = [aDecoder decodeObjectForKey:@"name"];
		self.characterID = [aDecoder decodeInt32ForKey:@"characterID"];
		self.type = [aDecoder decodeInt32ForKey:@"type"];
	}
	return self;
}

- (void) encodeWithCoder:(NSCoder *)aCoder {
	if (self.name)
		[aCoder encodeObject:self.name forKey:@"name"];
	[aCoder encodeInt32:self.characterID forKey:@"characterID"];
	[aCoder encodeInt32:self.type forKey:@"type"];
}

@end
