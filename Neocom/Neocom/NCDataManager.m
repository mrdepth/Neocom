//
//  NCDataManager.m
//  Neocom
//
//  Created by Artem Shimanski on 20.10.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCDataManager.h"
#import "NCStorage.h"
#import "NCCacheRecord.h"
#import "unitily.h"
@import EVEAPI;

@implementation NCDataManager

+ (instancetype) defaultManager {
	return [self new];
}

- (void) addAPIKeyWithKeyID:(NSInteger) keyID vCode:(NSString*) vCode excludeCharacterIDs:(NSIndexSet*) characterIDs completionBlock:(void(^)(NSArray<NSManagedObjectID*>* accounts, NSError* error)) completionBlock {
	EVEOnlineAPI* api = [EVEOnlineAPI apiWithAPIKey:[EVEAPIKey apiKeyWithKeyID:keyID vCode:vCode] cachePolicy:NSURLRequestReloadIgnoringLocalCacheData];
	[api apiKeyInfoWithCompletionBlock:^(EVEAPIKeyInfo *result, NSError *error) {
		if (result && !result.eveapi.error) {
			[[NCStorage sharedStorage] performBackgroundTask:^(NSManagedObjectContext *managedObjectContext) {
				NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"APIKey"];
				fetchRequest.predicate = [NSPredicate predicateWithFormat:@"keyID == %d", keyID];
				fetchRequest.fetchLimit = 1;
				NCAPIKey* apiKey = [[managedObjectContext executeFetchRequest:fetchRequest error:nil] lastObject];
				
				if (apiKey && ![apiKey.vCode isEqualToString:vCode]) {
					[managedObjectContext deleteObject:apiKey];
					apiKey = nil;
				}
				
				if (!apiKey) {
					apiKey = [NSEntityDescription insertNewObjectForEntityForName:@"APIKey" inManagedObjectContext:managedObjectContext];
					apiKey.keyID = (int32_t) keyID;
					apiKey.vCode = vCode;
					apiKey.apiKeyInfo = result;
				}
				
				NSMutableArray* accounts = [NSMutableArray new];
				NSExpressionDescription* ed = [NSExpressionDescription new];
				ed.name = @"order";
				ed.expressionResultType = NSInteger32AttributeType;
				ed.expression = [NSExpression expressionWithFormat:@"max(order)"];
				fetchRequest.predicate = [NSPredicate predicateWithFormat:@"order < %d", INT_MAX];
				fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"Account"];
				fetchRequest.propertiesToFetch = @[ed];
				fetchRequest.resultType = NSDictionaryResultType;
				int32_t order = [[[managedObjectContext executeFetchRequest:fetchRequest error:nil] lastObject][@"order"] intValue] + 1;
				
				for (EVEAPIKeyInfoCharactersItem* character in result.key.characters) {
					if ([characterIDs containsIndex:character.characterID])
						continue;
					
					NCAccount* account = nil;
					for (account in apiKey.accounts)
						if (account.characterID == character.characterID)
							break;
					if (!account) {
						account = [NSEntityDescription insertNewObjectForEntityForName:@"Account" inManagedObjectContext:managedObjectContext];
						account.apiKey = apiKey;
						account.characterID = character.characterID;
						account.order = order++;
						account.uuid = [[NSUUID UUID] UUIDString];
						[accounts addObject:account.objectID];
					}
				}
				
				dispatch_async(dispatch_get_main_queue(), ^{
					completionBlock(accounts, nil);
				});
			}];
		}
		else
			completionBlock(nil, error ?: result.eveapi.error);
	}];
}

- (void) apiKeyInfoWithKeyID:(NSInteger) keyID vCode:(NSString*) vCode completionBlock:(void(^)(EVEAPIKeyInfo* apiKeyInfo, NSError* error)) block {
	EVEOnlineAPI* api = [EVEOnlineAPI apiWithAPIKey:[EVEAPIKey apiKeyWithKeyID:keyID vCode:vCode] cachePolicy:NSURLRequestUseProtocolCachePolicy];
	[api apiKeyInfoWithCompletionBlock:^(EVEAPIKeyInfo *result, NSError *error) {
		block(result, error);
	}];
}

- (void) characterSheetForAccount:(NCAccount*) account cachePolicy:(NSURLRequestCachePolicy) cachePolicy completionHandler:(void(^)(EVECharacterSheet* result, NSError* error, NSManagedObjectID* cacheRecordID)) block {
	[self loadFromCacheForKey:@"EVECharacterSheet" account:account.uuid cachePolicy:cachePolicy completionHandler:block elseLoad:^(void (^finish)(id object, NSError *error, NSDate *date, NSDate *expireDate)) {
		EVEOnlineAPI* api = [EVEOnlineAPI apiWithAPIKey:account.eveAPIKey cachePolicy:cachePolicy];
		[api characterSheetWithCompletionBlock:^(EVECharacterSheet *result, NSError *error) {
			finish(result, error, [result.eveapi localTimeWithServerTime:result.eveapi.cacheDate], [result.eveapi localTimeWithServerTime:result.eveapi.cachedUntil]);
		}];
	}];
}

- (void) skillQueueForAccount:(NCAccount*) account cachePolicy:(NSURLRequestCachePolicy) cachePolicy completionHandler:(void(^)(EVESkillQueue* result, NSError* error, NSManagedObjectID* cacheRecordID)) block {
	[self loadFromCacheForKey:@"EVESkillQueue" account:account.uuid cachePolicy:cachePolicy completionHandler:block elseLoad:^(void (^finish)(id object, NSError *error, NSDate *date, NSDate *expireDate)) {
		EVEOnlineAPI* api = [EVEOnlineAPI apiWithAPIKey:account.eveAPIKey cachePolicy:cachePolicy];
		[api skillQueueWithCompletionBlock:^(EVESkillQueue *result, NSError *error) {
			finish(result, error, [result.eveapi localTimeWithServerTime:result.eveapi.cacheDate], [result.eveapi localTimeWithServerTime:result.eveapi.cachedUntil]);
		}];
	}];
}

- (void) characterInfoForAccount:(NCAccount*) account cachePolicy:(NSURLRequestCachePolicy) cachePolicy completionHandler:(void(^)(EVECharacterInfo* result, NSError* error, NSManagedObjectID* cacheRecordID)) block {
	[self loadFromCacheForKey:@"EVECharacterInfo" account:account.uuid cachePolicy:cachePolicy completionHandler:block elseLoad:^(void (^finish)(id object, NSError *error, NSDate *date, NSDate *expireDate)) {
		EVEOnlineAPI* api = [EVEOnlineAPI apiWithAPIKey:account.eveAPIKey cachePolicy:cachePolicy];
		[api characterInfoWithCharacterID:account.characterID completionBlock:^(EVECharacterInfo *result, NSError *error) {
			finish(result, error, [result.eveapi localTimeWithServerTime:result.eveapi.cacheDate], [result.eveapi localTimeWithServerTime:result.eveapi.cachedUntil]);
		}];
	}];
}

- (void) accountStatusForAccount:(NCAccount*) account cachePolicy:(NSURLRequestCachePolicy) cachePolicy completionHandler:(void(^)(EVEAccountStatus* result, NSError* error, NSManagedObjectID* cacheRecordID)) block {
	[self loadFromCacheForKey:@"EVEAccountStatus" account:account.uuid cachePolicy:cachePolicy completionHandler:block elseLoad:^(void (^finish)(id object, NSError *error, NSDate *date, NSDate *expireDate)) {
		EVEOnlineAPI* api = [EVEOnlineAPI apiWithAPIKey:account.eveAPIKey cachePolicy:cachePolicy];
		[api accountStatusWithCompletionBlock:^(EVEAccountStatus *result, NSError *error) {
			finish(result, error, [result.eveapi localTimeWithServerTime:result.eveapi.cacheDate], [result.eveapi localTimeWithServerTime:result.eveapi.cachedUntil]);
		}];
	}];
}

- (void) imageWithCharacterID:(NSInteger) characterID preferredSize:(CGSize) size scale:(CGFloat) scale cachePolicy:(NSURLRequestCachePolicy) cachePolicy completionBlock:(void(^)(UIImage* image, NSError* error, NSManagedObjectID *cacheRecordID)) block {
	size.width *= scale;
	size.height *= scale;

	EVEImageSize sizes[] = {EVEImageSize32, EVEImageSize64, EVEImageSize128, EVEImageSize256, EVEImageSize512, EVEImageSize1024};
	int n = sizeof(sizes) / sizeof(EVEImageSize);
	CGFloat dimension = MAX(size.width, size.height);
	EVEImageSize s = EVEImageSize32;
	for (int i = 0; i < n; i++) {
		s = sizes[i];
		if (sizes[i] > dimension)
			break;
	}
	
	NSString* key = [NSString stringWithFormat:@"EVEImage:character:%d:%d", (int) characterID, (int) s];
	[self loadFromCacheForKey:key account:nil cachePolicy:cachePolicy completionHandler:^(id result, NSError *error, NSManagedObjectID *cacheRecordID) {
		UIImage* image = [UIImage imageWithData:result scale:scale];
		block(image, error, cacheRecordID);
	} elseLoad:^(void (^finish)(id object, NSError *error, NSDate *date, NSDate *expireDate)) {
		NSURL* url = [EVEImage characterPortraitURLWithCharacterID:(int32_t) characterID size:s error:nil];
		EVEOnlineAPI* api = [[EVEOnlineAPI alloc] initWithAPIKey:nil cachePolicy:NSURLRequestUseProtocolCachePolicy];
		[api.sessionManager GET:url.absoluteString parameters:nil responseSerializer:[AFHTTPResponseSerializer serializer] completionBlock:^(id responseObject, NSError *error) {
			UIImage* image = [responseObject isKindOfClass:[NSData class]] ? [UIImage imageWithData:responseObject scale:scale] : nil;
			if (!image && !error)
				error = [NSError errorWithDomain:NCDefaultErrorDomain code:NCDefaultErrorCode userInfo:@{NSLocalizedDescriptionKey:NSLocalizedString(@"File not found", nil)}];
			finish(image ? responseObject : nil, error, [NSDate date], [NSDate dateWithTimeIntervalSinceNow:3600]);
		}];
	}];
}

- (void) imageWithCorporationID:(NSInteger) corporationID preferredSize:(CGSize) size scale:(CGFloat) scale cachePolicy:(NSURLRequestCachePolicy) cachePolicy completionBlock:(void(^)(UIImage* image, NSError* error, NSManagedObjectID *cacheRecordID)) block {
	size.width *= scale;
	size.height *= scale;
	
	EVEImageSize sizes[] = {EVEImageSize32, EVEImageSize64, EVEImageSize128, EVEImageSize256};
	int n = sizeof(sizes) / sizeof(EVEImageSize);
	CGFloat dimension = MAX(size.width, size.height);
	EVEImageSize s = EVEImageSize32;
	for (int i = 0; i < n; i++) {
		s = sizes[i];
		if (sizes[i] > dimension)
		break;
	}
	
	NSString* key = [NSString stringWithFormat:@"EVEImage:corporation:%d:%d", (int) corporationID, (int) s];
	[self loadFromCacheForKey:key account:nil cachePolicy:cachePolicy completionHandler:^(id result, NSError *error, NSManagedObjectID *cacheRecordID) {
		UIImage* image = [UIImage imageWithData:result scale:scale];
		block(image, error, cacheRecordID);
	} elseLoad:^(void (^finish)(id object, NSError *error, NSDate *date, NSDate *expireDate)) {
		NSURL* url = [EVEImage corporationLogoURLWithCorporationID:(int32_t) corporationID size:s error:nil];
		EVEOnlineAPI* api = [[EVEOnlineAPI alloc] initWithAPIKey:nil cachePolicy:NSURLRequestUseProtocolCachePolicy];
		[api.sessionManager GET:url.absoluteString parameters:nil responseSerializer:[AFHTTPResponseSerializer serializer] completionBlock:^(id responseObject, NSError *error) {
			UIImage* image = [responseObject isKindOfClass:[NSData class]] ? [UIImage imageWithData:responseObject scale:scale] : nil;
			if (!image && !error)
				error = [NSError errorWithDomain:NCDefaultErrorDomain code:NCDefaultErrorCode userInfo:@{NSLocalizedDescriptionKey:NSLocalizedString(@"File not found", nil)}];
			finish(image ? responseObject : nil, error, [NSDate date], [NSDate dateWithTimeIntervalSinceNow:3600]);
		}];
	}];
}

- (void) imageWithAllianceID:(NSInteger) allianceID preferredSize:(CGSize) size scale:(CGFloat) scale cachePolicy:(NSURLRequestCachePolicy) cachePolicy completionBlock:(void(^)(UIImage* image, NSError* error, NSManagedObjectID *cacheRecordID)) block {
	size.width *= scale;
	size.height *= scale;
	
	EVEImageSize sizes[] = {EVEImageSize32, EVEImageSize64, EVEImageSize128};
	int n = sizeof(sizes) / sizeof(EVEImageSize);
	CGFloat dimension = MAX(size.width, size.height);
	EVEImageSize s = EVEImageSize32;
	for (int i = 0; i < n; i++) {
		s = sizes[i];
		if (sizes[i] > dimension)
		break;
	}
	
	NSString* key = [NSString stringWithFormat:@"EVEImage:alliance:%d:%d", (int) allianceID, (int) s];
	[self loadFromCacheForKey:key account:nil cachePolicy:cachePolicy completionHandler:^(id result, NSError *error, NSManagedObjectID *cacheRecordID) {
		UIImage* image = [UIImage imageWithData:result scale:scale];
		block(image, error, cacheRecordID);
	} elseLoad:^(void (^finish)(id object, NSError *error, NSDate *date, NSDate *expireDate)) {
		NSURL* url = [EVEImage allianceLogoURLWithAllianceID:(int32_t) allianceID size:s error:nil];
		EVEOnlineAPI* api = [[EVEOnlineAPI alloc] initWithAPIKey:nil cachePolicy:NSURLRequestUseProtocolCachePolicy];
		[api.sessionManager GET:url.absoluteString parameters:nil responseSerializer:[AFHTTPResponseSerializer serializer] completionBlock:^(id responseObject, NSError *error) {
			UIImage* image = [responseObject isKindOfClass:[NSData class]] ? [UIImage imageWithData:responseObject scale:scale] : nil;
			if (!image && !error)
				error = [NSError errorWithDomain:NCDefaultErrorDomain code:NCDefaultErrorCode userInfo:@{NSLocalizedDescriptionKey:NSLocalizedString(@"File not found", nil)}];
			finish(image ? responseObject : nil, error, [NSDate date], [NSDate dateWithTimeIntervalSinceNow:3600]);
		}];
	}];
}

- (void) imageWithTypeID:(NSInteger) typeID preferredSize:(CGSize) size scale:(CGFloat) scale cachePolicy:(NSURLRequestCachePolicy) cachePolicy completionBlock:(void(^)(UIImage* image, NSError* error, NSManagedObjectID *cacheRecordID)) block {
	size.width *= scale;
	size.height *= scale;
	
	EVEImageSize sizes[] = {EVEImageSize32, EVEImageSize64, EVEImageSize128, EVEImageSize256, EVEImageSize512};
	int n = sizeof(sizes) / sizeof(EVEImageSize);
	CGFloat dimension = MAX(size.width, size.height);
	EVEImageSize s = EVEImageSize32;
	for (int i = 0; i < n; i++) {
		s = sizes[i];
		if (sizes[i] > dimension)
			break;
	}
	
	NSString* key = [NSString stringWithFormat:@"EVEImage:type:%d:%d", (int) typeID, (int) s];
	[self loadFromCacheForKey:key account:nil cachePolicy:cachePolicy completionHandler:^(id result, NSError *error, NSManagedObjectID *cacheRecordID) {
		UIImage* image = [UIImage imageWithData:result scale:scale];
		block(image, error, cacheRecordID);
	} elseLoad:^(void (^finish)(id object, NSError *error, NSDate *date, NSDate *expireDate)) {
		NSURL* url = [EVEImage renderImageURLWithTypeID:(int32_t) typeID size:s error:nil];
		EVEOnlineAPI* api = [[EVEOnlineAPI alloc] initWithAPIKey:nil cachePolicy:NSURLRequestUseProtocolCachePolicy];
		[api.sessionManager GET:url.absoluteString parameters:nil responseSerializer:[AFHTTPResponseSerializer serializer] completionBlock:^(id responseObject, NSError *error) {
			UIImage* image = [responseObject isKindOfClass:[NSData class]] ? [UIImage imageWithData:responseObject scale:scale] : nil;
			if (!image && !error)
				error = [NSError errorWithDomain:NCDefaultErrorDomain code:NCDefaultErrorCode userInfo:@{NSLocalizedDescriptionKey:NSLocalizedString(@"File not found", nil)}];
			finish(image ? responseObject : nil, error, [NSDate date], [NSDate dateWithTimeIntervalSinceNow:3600]);
		}];
	}];
}

- (void) callListWithCachePolicy:(NSURLRequestCachePolicy) cachePolicy completionHandler:(void(^)(EVECallList* result, NSError* error, NSManagedObjectID* cacheRecordID)) block {
	[self loadFromCacheForKey:@"EVECallList" account:nil cachePolicy:cachePolicy completionHandler:block elseLoad:^(void (^finish)(id object, NSError *error, NSDate *date, NSDate *expireDate)) {
		EVEOnlineAPI* api = [EVEOnlineAPI apiWithAPIKey:nil cachePolicy:cachePolicy];
		[api callListWithCompletionBlock:^(EVECallList *result, NSError *error) {
			finish(result, error, [result.eveapi localTimeWithServerTime:result.eveapi.cacheDate], [result.eveapi localTimeWithServerTime:result.eveapi.cachedUntil]);
		}];
	}];
}

- (void) accountBalanceForAccount:(NCAccount*) account cachePolicy:(NSURLRequestCachePolicy) cachePolicy completionHandler:(void(^)(EVEAccountBalance* result, NSError* error, NSManagedObjectID* cacheRecordID)) block {
	[self loadFromCacheForKey:@"EVEAccountBalance" account:account.uuid cachePolicy:cachePolicy completionHandler:block elseLoad:^(void (^finish)(id object, NSError *error, NSDate *date, NSDate *expireDate)) {
		EVEOnlineAPI* api = [EVEOnlineAPI apiWithAPIKey:account.eveAPIKey cachePolicy:cachePolicy];
		[api accountBalanceWithCompletionBlock:^(EVEAccountBalance *result, NSError *error) {
			finish(result, error, [result.eveapi localTimeWithServerTime:result.eveapi.cacheDate], [result.eveapi localTimeWithServerTime:result.eveapi.cachedUntil]);
		}];
	}];
}

- (void) locationWithLocationIDs:(NSArray<NSNumber*>*) locationIDs cachePolicy:(NSURLRequestCachePolicy) cachePolicy completionHandler:(void(^)(NSDictionary<NSNumber*, NCLocation*>* result, NSError* error)) block {
	
	NSMutableDictionary* names = [NSMutableDictionary new];
	NSMutableArray* conquerableStationIDs = [NSMutableArray new];
	
	for (NSNumber* item in locationIDs) {
		NCLocation* location = nil;
		int32_t locationID = [item intValue];
		if (66000000 < locationID && locationID < 66014933) { //staStations
			locationID -= 6000001;
			NCDBStaStation *station = NCDatabase.sharedDatabase.staStations[locationID];
			if (station)
				location = [[NCLocation alloc] initWithStation:station];
		}
		else if (66014934 < locationID && locationID < 67999999) { //staStations
			locationID -= 6000000;
			[conquerableStationIDs addObject:@(locationID)];
		}
		else if (60014861 < locationID && locationID < 60014928) { //ConqStations
			[conquerableStationIDs addObject:@(locationID)];
		}
		else if (60000000 < locationID && locationID < 61000000) { //staStations
			NCDBStaStation *station = NCDatabase.sharedDatabase.staStations[locationID];
			if (station)
				location = [[NCLocation alloc] initWithStation:station];
		}
		else if (61000000 <= locationID) { //ConqStations
			[conquerableStationIDs addObject:@(locationID)];
		}
		else { //mapDenormalize
			NCDBMapDenormalize* denormalize = NCDatabase.sharedDatabase.mapDenormalize[locationID];
			if (denormalize)
				location = [[NCLocation alloc] initWithMapDenormalize:denormalize];
		}
		if (location)
			names[@(locationID)] = location;
	}
	

	
	if (conquerableStationIDs.count > 0) {
		[self loadFromCacheForKey:@"EVEConquerableStationList" account:nil cachePolicy:NSURLRequestUseProtocolCachePolicy completionHandler:^(id result, NSError *error, NSManagedObjectID *cacheRecordID) {
			NSDictionary* outposts = result;
			if (outposts) {
				for (NSNumber* item in conquerableStationIDs) {
					int32_t locationID = [item intValue];
					EVEConquerableStationListItem* station = outposts[@(locationID)];
					NCLocation* location = station ? [[NCLocation alloc] initWithConquerableStation:station] : nil;
					if (location)
						names[@(locationID)] = location;
				}
			}
			block(names, error);
			
		} elseLoad:^(void (^finish)(id object, NSError *error, NSDate *date, NSDate *expireDate)) {
			EVEOnlineAPI* api = [EVEOnlineAPI apiWithAPIKey:nil cachePolicy:cachePolicy];
			[api conquerableStationListWithCompletionBlock:^(EVEConquerableStationList *result, NSError *error) {
				NSMutableDictionary* outposts;
				if (result) {
					outposts = [NSMutableDictionary new];
					for (EVEConquerableStationListItem* station in result.outposts)
						outposts[@(station.stationID)] = station;
				}
				finish(outposts, error, [result.eveapi localTimeWithServerTime:result.eveapi.cacheDate], [result.eveapi localTimeWithServerTime:result.eveapi.cachedUntil]);
			}];
		}];
	}
	else {
		dispatch_async(dispatch_get_main_queue(), ^{
			block(names, nil);
		});
	}

}

#pragma mark - Private

- (void) loadFromCacheForKey:(NSString*) key account:(NSString*) account cachePolicy:(NSURLRequestCachePolicy) cachePolicy completionHandler:(void(^)(id result, NSError* error, NSManagedObjectID* cacheRecordID)) block elseLoad:(void(^)(void(^finish)(id object, NSError* error, NSDate* date, NSDate* expireDate))) loader {
	NCCache* cache = [NCCache sharedCache];

	NSProgress* progress = [NSProgress progressWithTotalUnitCount:1];
	
	switch (cachePolicy) {
		case NSURLRequestReloadIgnoringLocalCacheData: {
			[progress becomeCurrentWithPendingUnitCount:1];
			loader(^(id object, NSError* error, NSDate* date, NSDate* expireDate) {
				if (object)
					[cache storeObject:object forKey:key account:account date:date expireDate:expireDate error:nil completionHandler:^(NSManagedObjectID *objectID) {
						block(object, error, objectID);
					}];
				else
					[cache storeObject:nil forKey:key account:account date:[NSDate date] expireDate:[NSDate dateWithTimeIntervalSinceNow:3] error:error completionHandler:^(NSManagedObjectID *objectID) {
						block(nil, error, objectID);
					}];
			});
			[progress resignCurrent];
			break;
		}
		case NSURLRequestReturnCacheDataElseLoad: {
			[cache performBackgroundTask:^(NSManagedObjectContext *managedObjectContext) {
				NCCacheRecord* record = [[managedObjectContext executeFetchRequest:[NCCacheRecord fetchRequestForKey:key account:account] error:nil] lastObject];
				id object = record.object;
				dispatch_async(dispatch_get_main_queue(), ^{
					if (object) {
						progress.completedUnitCount++;

						block(object, nil, record.objectID);
					}
					else {
						[progress becomeCurrentWithPendingUnitCount:1];
						loader(^(id object, NSError* error, NSDate* date, NSDate* expireDate) {
							if (object)
								[cache storeObject:object forKey:key account:account date:date expireDate:expireDate error:nil completionHandler:^(NSManagedObjectID *objectID) {
									block(object, error, objectID);
								}];
							else
								[cache storeObject:nil forKey:key account:account date:[NSDate date] expireDate:[NSDate dateWithTimeIntervalSinceNow:3] error:error completionHandler:^(NSManagedObjectID *objectID) {
									block(nil, error, objectID);
								}];
						});
						[progress resignCurrent];
					}
				});
			}];
			break;
		}
		case NSURLRequestReturnCacheDataDontLoad: {
			[cache performBackgroundTask:^(NSManagedObjectContext *managedObjectContext) {
				NCCacheRecord* record = [[managedObjectContext executeFetchRequest:[NCCacheRecord fetchRequestForKey:key account:account] error:nil] lastObject];
				id object = record.object;
				dispatch_async(dispatch_get_main_queue(), ^{
					progress.completedUnitCount++;
					block(object, object ? nil : [NSError errorWithDomain:NCDefaultErrorDomain code:NCDefaultErrorCode userInfo:@{NSLocalizedDescriptionKey:NSLocalizedString(@"No cached data found", nil)}], record.objectID);
				});
			}];
			break;
		}
		default: {
			[cache performBackgroundTask:^(NSManagedObjectContext *managedObjectContext) {
				NCCacheRecord* record = [[managedObjectContext executeFetchRequest:[NCCacheRecord fetchRequestForKey:key account:account] error:nil] lastObject];
				id object = record.object;
				BOOL isExpired = record.isExpired;
				dispatch_async(dispatch_get_main_queue(), ^{
					if (object) {
						progress.completedUnitCount++;
						block(object, nil, record.objectID);
						if (isExpired)
							loader(^(id object, NSError* error, NSDate* date, NSDate* expireDate) {
								if (object)
									[cache storeObject:object forKey:key account:account date:date expireDate:expireDate error:nil completionHandler:nil];
								else
									[cache storeObject:nil forKey:key account:account date:[NSDate date] expireDate:[NSDate dateWithTimeIntervalSinceNow:3] error:error completionHandler:nil];
							});
					}
					else {
						[progress becomeCurrentWithPendingUnitCount:1];
						loader(^(id object, NSError* error, NSDate* date, NSDate* expireDate) {
							if (object)
								[cache storeObject:object forKey:key account:account date:date expireDate:expireDate error:nil completionHandler:^(NSManagedObjectID *objectID) {
									block(object, error, objectID);
								}];
							else
								[cache storeObject:nil forKey:key account:account date:[NSDate date] expireDate:[NSDate dateWithTimeIntervalSinceNow:3] error:error completionHandler:^(NSManagedObjectID *objectID) {
									block(nil, error, objectID);
								}];
						});
						[progress resignCurrent];
					}
				});
			}];;
			break;
		}
	}
}

@end
