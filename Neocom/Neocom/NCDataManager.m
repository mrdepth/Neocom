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


- (void) imageWithCharacterID:(NSInteger) characterID preferredSize:(CGSize) size scale:(CGFloat) scale cachePolicy:(NSURLRequestCachePolicy) cachePolicy completionBlock:(void(^)(UIImage* image, NSError* error)) block {
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
		UIImage* image;
		if ([result isKindOfClass:[NSData class]])
			image = [[UIImage alloc] initWithData:result];
		block(image, error);
		
	} elseLoad:^(void (^finish)(id object, NSError *error, NSDate *date, NSDate *expireDate)) {
		NSURL* url = [EVEImage characterPortraitURLWithCharacterID:(int32_t) characterID size:s error:nil];
		EVEOnlineAPI* api = [[EVEOnlineAPI alloc] initWithAPIKey:nil cachePolicy:NSURLRequestUseProtocolCachePolicy];
		[api.sessionManager GET:url.absoluteString parameters:nil responseSerializer:[AFHTTPResponseSerializer serializer] completionBlock:^(id responseObject, NSError *error) {
			if (![responseObject isKindOfClass:[NSData class]])
				responseObject = nil;
			finish(responseObject, error, [NSDate date], [NSDate dateWithTimeIntervalSinceNow:3600]);

		}];
	}];
}

- (void) imageWithCorporationID:(NSInteger) corporationID preferredSize:(CGSize) size scale:(CGFloat) scale cachePolicy:(NSURLRequestCachePolicy) cachePolicy completionBlock:(void(^)(UIImage* image, NSError* error)) block {
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
		
	} elseLoad:^(void (^finish)(id object, NSError *error, NSDate *date, NSDate *expireDate)) {
		NSURL* url = [EVEImage corporationLogoURLWithCorporationID:(int32_t) corporationID size:s error:nil];
		EVEOnlineAPI* api = [[EVEOnlineAPI alloc] initWithAPIKey:nil cachePolicy:NSURLRequestUseProtocolCachePolicy];
		[api.sessionManager GET:url.absoluteString parameters:nil responseSerializer:[AFHTTPResponseSerializer serializer] completionBlock:^(id responseObject, NSError *error) {
			UIImage* image;
			if ([responseObject isKindOfClass:[NSData class]])
			image = [[UIImage alloc] initWithData:responseObject];
			block(image, error);
		}];
	}];
}

- (void) imageWithAllianceID:(NSInteger) allianceID preferredSize:(CGSize) size scale:(CGFloat) scale cachePolicy:(NSURLRequestCachePolicy) cachePolicy completionBlock:(void(^)(UIImage* image, NSError* error)) block {
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
		
	} elseLoad:^(void (^finish)(id object, NSError *error, NSDate *date, NSDate *expireDate)) {
		NSURL* url = [EVEImage allianceLogoURLWithAllianceID:(int32_t) allianceID size:s error:nil];
		EVEOnlineAPI* api = [[EVEOnlineAPI alloc] initWithAPIKey:nil cachePolicy:NSURLRequestUseProtocolCachePolicy];
		[api.sessionManager GET:url.absoluteString parameters:nil responseSerializer:[AFHTTPResponseSerializer serializer] completionBlock:^(id responseObject, NSError *error) {
			UIImage* image;
			if ([responseObject isKindOfClass:[NSData class]])
			image = [[UIImage alloc] initWithData:responseObject];
			block(image, error);
		}];
	}];
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
					[cache storeObject:object forKey:key account:account date:date expireDate:expireDate completionHandler:^(NSManagedObjectID *objectID) {
						block(object, error, objectID);
					}];
				else
					block(nil, error, nil);
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
								[cache storeObject:object forKey:key account:account date:date expireDate:expireDate completionHandler:^(NSManagedObjectID *objectID) {
									block(object, error, objectID);
								}];
							else
								block(nil, error, nil);
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
					block(object, object ? nil : [NSError errorWithDomain:@"NCDataManager" code:-1 userInfo:@{NSLocalizedDescriptionKey:NSLocalizedString(@"No cached data found", nil)}], record.objectID);
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
									[cache storeObject:object forKey:key account:account date:date expireDate:expireDate completionHandler:nil];
							});
					}
					else {
						[progress becomeCurrentWithPendingUnitCount:1];
						loader(^(id object, NSError* error, NSDate* date, NSDate* expireDate) {
							if (object)
								[cache storeObject:object forKey:key account:account date:date expireDate:expireDate completionHandler:^(NSManagedObjectID *objectID) {
									block(object, error, objectID);
								}];
							else
								block(nil, error, nil);
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
