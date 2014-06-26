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
	
	[cache.managedObjectContext performBlockAndWait:^{
		cacheRecord = [NCCacheRecord cacheRecordWithRecordID:@"NCCharacterID"];
		if ([cacheRecord.expireDate compare:[NSDate date]] == NSOrderedDescending)
			nameToCharacterID = [cacheRecord.data.data mutableCopy];
	}];
	
	if (!nameToCharacterID) {
		nameToCharacterID = [NSMutableDictionary new];
		cacheRecord.date = [NSDate date];
		cacheRecord.expireDate = [NSDate dateWithTimeIntervalSinceNow:60 * 60 * 24 * 2];
	}
		
	NCCharacterID* characterID = nameToCharacterID[name];
	
	if (!characterID && ![NSThread isMainThread]) {
		EVEOwnerID* ownerID = [EVEOwnerID ownerIDWithNames:@[name] cachePolicy:NSURLRequestUseProtocolCachePolicy error:nil progressHandler:nil];
		if (ownerID.owners.count > 0) {
			EVEOwnerIDItem* ownerIDItem = ownerID.owners[0];
			characterID = [NCCharacterID new];
			characterID.characterID = ownerIDItem.ownerID;
			if (ownerIDItem.ownerGroupID == EVEOwnerGroupCharacter)
				characterID.type = NCCharacterIDTypeCharacter;
			else if (ownerIDItem.ownerGroupID == EVEOwnerGroupCorporation)
				characterID.type = NCCharacterIDTypeCorporation;
			else
				characterID.type = NCCharacterIDTypeAlliance;
			characterID.name = ownerIDItem.ownerName;
			nameToCharacterID[name] = characterID;
		}
	}
	
	[cache.managedObjectContext performBlockAndWait:^{
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
