//
//  NCCharacterID.m
//  Neocom
//
//  Created by Артем Шиманский on 27.02.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCCharacterID.h"
#import <EVEAPI/EVEAPI.h>
#import "NCCache.h"

@interface NCCharacterID()<NSCoding>
@property (nonatomic, assign, readwrite) NCCharacterIDType type;
@property (nonatomic, assign, readwrite) int32_t characterID;
@property (nonatomic, strong, readwrite) NSString* name;
@property (nonatomic, strong) NSManagedObjectContext* cacheManagedObjectContext;

@end

@implementation NCCharacterID

+ (void) requestCharacterIDWithName:(NSString*) name completionBlock:(void(^)(NCCharacterID* characterID, NSError* error)) completionBlock {
	name = [name lowercaseString];
	__block NSManagedObjectContext* managedObjectContext = [[NCCache sharedCache] createManagedObjectContext];
	
	[managedObjectContext performBlock:^{
		NCCacheRecord* cacheRecord = [NCCacheRecord cacheRecordWithRecordID:@"NCCharacterID"];
		NSMutableDictionary* nameToCharacterID = [cacheRecord.data.data mutableCopy];
		
		if (!nameToCharacterID) {
			nameToCharacterID = [NSMutableDictionary new];
		}
		NCCharacterID* characterID = nameToCharacterID[name];
		
		if (!characterID) {
			EVEOnlineAPI* api = [[EVEOnlineAPI alloc] initWithAPIKey:nil cachePolicy:NSURLRequestUseProtocolCachePolicy];
			[api ownerIDWithNames:@[name] completionBlock:^(EVEOwnerID *ownerID, NSError *error) {
				if (ownerID.owners.count > 0) {
					EVEOwnerIDItem* ownerIDItem = ownerID.owners[0];
					NCCharacterID* characterID = [NCCharacterID new];
					characterID.characterID = ownerIDItem.ownerID;
					if (ownerIDItem.ownerGroupID == EVEOwnerGroupCharacter)
						characterID.type = NCCharacterIDTypeCharacter;
					else if (ownerIDItem.ownerGroupID == EVEOwnerGroupCorporation)
						characterID.type = NCCharacterIDTypeCorporation;
					else
						characterID.type = NCCharacterIDTypeAlliance;
					characterID.name = ownerIDItem.ownerName;
					nameToCharacterID[name] = characterID;
					
					[managedObjectContext performBlock:^{
						if (![nameToCharacterID isEqualToDictionary:cacheRecord.data.data])
							cacheRecord.data.data = nameToCharacterID;
						[managedObjectContext save:nil];
						managedObjectContext = nil;
					}];
					completionBlock(characterID, nil);
				}
				else {
					completionBlock(nil, error);
					managedObjectContext = nil;
				}
			}
					progressBlock:nil];
		}
		else {
			dispatch_async(dispatch_get_main_queue(), ^{
				completionBlock(characterID, nil);
				managedObjectContext = nil;
			});
		}
	}];
}


- (BOOL) isEqual:(id)object {
	if ([object isKindOfClass:self.class] && self.characterID == [(NCCharacterID*) object characterID])
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
