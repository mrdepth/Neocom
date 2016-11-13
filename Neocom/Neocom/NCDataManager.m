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

- (void) addAPIKeyWithKeyID:(int32_t) keyID vCode:(NSString*) vCode completionBlock:(void(^)(NSArray<NSManagedObjectID*>* accounts, NSError* error)) completionBlock {
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
					apiKey.keyID = keyID;
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
