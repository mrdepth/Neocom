//
//  NCAccount.m
//  Neocom
//
//  Created by Admin on 04.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCAccount.h"
#import "NCStorage.h"
#import "NCCache.h"
#import "NSCache+Neocom.h"

#define NCAccountSkillPointsUpdateInterval (60.0 * 10.0)

@interface NCCacheRecord(NCAccount)
- (void) cacheResult:(EVEResult*) result;
@end

@implementation NCCacheRecord(NCAccount)

- (void) cacheResult:(EVEResult*) result {
	if (result) {
		self.data.data = result;
		self.date = result.eveapi.cacheDate;
		self.expireDate = result.eveapi.cachedUntil;
	}
	else {
		self.date = [NSDate date];
		self.expireDate = [NSDate dateWithTimeIntervalSinceNow:3];
	}
	[self.managedObjectContext save:nil];
}

@end


static NCAccount* currentAccount = nil;

@interface NCAccount()
@property (nonatomic, strong) NSCache* cache;
@end

@implementation NCStorage(NCAccount)

- (NSArray*) allAccounts {
	NSManagedObjectContext* context = [NSThread isMainThread] ? self.managedObjectContext : self.backgroundManagedObjectContext;
	
	__block NSArray* accounts = nil;
	[context performBlockAndWait:^{
		NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
		NSEntityDescription *entity = [NSEntityDescription entityForName:@"Account" inManagedObjectContext:context];
		[fetchRequest setEntity:entity];
		[fetchRequest setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"order" ascending:YES], [NSSortDescriptor sortDescriptorWithKey:@"characterID" ascending:YES]]];
		
		accounts = [context executeFetchRequest:fetchRequest error:nil];
	}];
	return accounts;
}

- (NCAccount*) accountWithUUID:(NSString*) uuid {
	NSManagedObjectContext* context = [NSThread isMainThread] ? self.managedObjectContext : self.backgroundManagedObjectContext;
	
	__block NSArray* accounts = nil;
	[context performBlockAndWait:^{
		NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
		NSEntityDescription *entity = [NSEntityDescription entityForName:@"Account" inManagedObjectContext:context];
		[fetchRequest setEntity:entity];
		fetchRequest.predicate = [NSPredicate predicateWithFormat:@"uuid == %@", uuid];
		accounts = [context executeFetchRequest:fetchRequest error:nil];
	}];
	return accounts.count > 0 ? accounts[0] : nil;
}

@end

@implementation NCAccount

@dynamic characterID;
@dynamic order;
@dynamic apiKey;
@dynamic skillPlans;
@dynamic mailBox;
@dynamic uuid;

@synthesize activeSkillPlan = _activeSkillPlan;


+ (instancetype) currentAccount {
	@synchronized(self) {
		return currentAccount;
	}
}


+ (void) setCurrentAccount:(NCAccount*) account {
	BOOL changed = NO;
	@synchronized(self) {
		changed = currentAccount != account;
		if (changed) {
			currentAccount = account;
			if (account) {
				[[NSUserDefaults standardUserDefaults] setValue:account.uuid forKey:NCSettingsCurrentAccountKey];
			}
			else
				[[NSUserDefaults standardUserDefaults] removeObjectForKey:NCSettingsCurrentAccountKey];
			[[NSUserDefaults standardUserDefaults] synchronize];
		}
	}
	if (changed)
		[[NSNotificationCenter defaultCenter] postNotificationName:NCCurrentAccountDidChangeNotification object:account];
}

- (void) awakeFromInsert {
	[super awakeFromInsert];
	self.cache = [NSCache new];
	NCStorage* storage = [NCStorage sharedStorage];
	NSManagedObjectContext* context = [NSThread isMainThread] ? storage.managedObjectContext : storage.backgroundManagedObjectContext;

	self.mailBox = [[NCMailBox alloc] initWithEntity:[NSEntityDescription entityForName:@"MailBox" inManagedObjectContext:context]
					  insertIntoManagedObjectContext:context];
}

- (void) awakeFromFetch {
	[super awakeFromFetch];
	self.cache = [NSCache new];
}

- (void) willSave {
	if ([self isDeleted]) {
		NCCache* cache = [NCCache sharedCache];
		NSManagedObjectContext* context = cache.managedObjectContext;
		[context performBlock:^{
			NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
			NSEntityDescription *entity = [NSEntityDescription entityForName:@"Record" inManagedObjectContext:context];
			[fetchRequest setEntity:entity];
			[fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"recordID like %@", [NSString stringWithFormat:@"*%@*", self.uuid]]];

			NSArray *fetchedObjects = [context executeFetchRequest:fetchRequest error:nil];
			for (NCCacheRecord* record in fetchedObjects)
				[cache.managedObjectContext deleteObject:record];

			[cache saveContext];
		}];
	}
	
	[super willSave];
}

- (NCAccountType) accountType {
	return self.apiKey.apiKeyInfo.key.type == EVEAPIKeyTypeCorporation ? NCAccountTypeCorporate : NCAccountTypeCharacter;
}

- (NCSkillPlan*) activeSkillPlan {
	if (!_activeSkillPlan || [_activeSkillPlan isDeleted]) {
		NCStorage* storage = [NCStorage sharedStorage];
		NSManagedObjectContext* context = [NSThread isMainThread] ? storage.managedObjectContext : storage.backgroundManagedObjectContext;
		
		if (self.skillPlans.count == 0) {
			_activeSkillPlan = [[NCSkillPlan alloc] initWithEntity:[NSEntityDescription entityForName:@"SkillPlan" inManagedObjectContext:context]
								   insertIntoManagedObjectContext:context];
			_activeSkillPlan.active = YES;
			_activeSkillPlan.account = self;
			_activeSkillPlan.name = NSLocalizedString(@"Default Skill Plan", nil);
		}
		else {
			NSSet* skillPlans = [self.skillPlans filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"active == YES"]];
			if (skillPlans.count == 0) {
				_activeSkillPlan = [self.skillPlans anyObject];
				_activeSkillPlan.active = YES;
			}
			else if (skillPlans.count > 1) {
				NSMutableSet* set = [[NSMutableSet alloc] initWithSet:skillPlans];
				_activeSkillPlan = [set anyObject];
				[set removeObject:_activeSkillPlan];
				for (NCSkillPlan* item in set)
					item.active = NO;
			}
			else
				_activeSkillPlan = [skillPlans anyObject];
		}
		if ([context hasChanges])
			[context save:nil];
	}
	return _activeSkillPlan;
}

- (void) setActiveSkillPlan:(NCSkillPlan *)activeSkillPlan {
	[self willChangeValueForKey:@"activeSkillPlan"];
	for (NCSkillPlan* skillPlan in self.skillPlans)
		if (![skillPlan isDeleted])
			skillPlan.active = NO;
	activeSkillPlan.active = YES;
	_activeSkillPlan = activeSkillPlan;
	[self didChangeValueForKey:@"activeSkillPlan"];
}

- (void) loadCharacterInfoWithCompletionBlock:(void(^)(EVECharacterInfo* characterInfo, NSError* error)) completionBlock {
	void (^finalize)(EVECharacterInfo*, NSError* error) = ^(EVECharacterInfo* characterInfo, NSError* error){
		if (characterInfo) {
			[self loadCharacterSheetWithCompletionBlock:^(EVECharacterSheet *characterSheet, NSError *error2) {
				if (characterSheet) {
					int32_t skillPoints = 0;
					for (EVECharacterSheetSkill* skill in characterSheet.skills)
						skillPoints += skill.skillpoints;
					characterInfo.skillPoints = skillPoints;
				}
				dispatch_async(dispatch_get_main_queue(), ^{
					if (characterInfo)
						[[NSNotificationCenter defaultCenter] postNotificationName:NCAccountDidChangeNotification object:self userInfo:@{@"characterInfo":characterInfo}];
					completionBlock(characterInfo, nil);
				});
			}];
		}
		else
			dispatch_async(dispatch_get_main_queue(), ^{
				completionBlock(characterInfo, nil);
			});
	};
	
	[self.managedObjectContext performBlock:^{
		NSString* key = [NSString stringWithFormat:@"%@.characterInfo", self.uuid];
		NSManagedObjectContext* cacheContext = [[NCCache sharedCache] managedObjectContext];
		[cacheContext performBlock:^{
			NCCacheRecord* cacheRecord = self.cache[key];
			if (!cacheRecord)
				self.cache[key] = cacheRecord = [NCCacheRecord cacheRecordWithRecordID:key];
			EVECharacterInfo* characterInfo = cacheRecord.data.data;
			if (!characterInfo) {
				[self.managedObjectContext performBlock:^{
					[[EVEOnlineAPI apiWithAPIKey:self.eveAPIKey cachePolicy:NSURLRequestUseProtocolCachePolicy] characterInfoWithCharacterID:self.characterID
																															 completionBlock:^(EVECharacterInfo *result, NSError *error) {
																																 [cacheContext performBlock:^{
																																	 [cacheRecord cacheResult:result];
																																 }];
																																 finalize(result, error);
																															 }
																															   progressBlock:nil];
				}];
			}
			else
				finalize(characterInfo, nil);
		}];

	}];
}

- (void) loadCharacterSheetWithCompletionBlock:(void(^)(EVECharacterSheet* characterSheet, NSError* error)) completionBlock {
	void (^finalize)(EVECharacterSheet*, NSError* error) = ^(EVECharacterSheet* characterSheet, NSError* error){
		if (characterSheet) {
			[self loadSkillQueueWithCompletionBlock:^(EVESkillQueue *skillQueue, NSError *error2) {
				if (skillQueue)
					[characterSheet attachSkillQueue:skillQueue];
				dispatch_async(dispatch_get_main_queue(), ^{
					if (characterSheet)
						[[NSNotificationCenter defaultCenter] postNotificationName:NCAccountDidChangeNotification object:self userInfo:@{@"characterSheet":characterSheet}];
					completionBlock(characterSheet, error);
				});
			}];
		}
		else
			dispatch_async(dispatch_get_main_queue(), ^{
				completionBlock(characterSheet, error);
			});
	};

	[self.managedObjectContext performBlock:^{
		NSString* key = [NSString stringWithFormat:@"%@.characterSheet", self.uuid];
		NSManagedObjectContext* cacheContext = [[NCCache sharedCache] managedObjectContext];
		[cacheContext performBlock:^{
			NCCacheRecord* cacheRecord = self.cache[key];
			if (!cacheRecord)
				self.cache[key] = cacheRecord = [NCCacheRecord cacheRecordWithRecordID:key];
			EVECharacterSheet* characterSheet = cacheRecord.data.data;
			if (!characterSheet) {
				[self.managedObjectContext performBlock:^{
					[[EVEOnlineAPI apiWithAPIKey:self.eveAPIKey cachePolicy:NSURLRequestUseProtocolCachePolicy] characterSheetWithCompletionBlock:^(EVECharacterSheet *result, NSError *error) {
						[cacheContext performBlock:^{
							[cacheRecord cacheResult:result];
						}];
						finalize(result, error);
					}
																																	progressBlock:nil];
				}];
			}
			else
				finalize(characterSheet, nil);
		}];
	}];
}

- (void) loadCorporationSheetWithCompletionBlock:(void(^)(EVECorporationSheet* corporationSheet, NSError* error)) completionBlock {
	[self.managedObjectContext performBlock:^{
		NSString* key = [NSString stringWithFormat:@"%@.corporationSheet", self.uuid];
		NSManagedObjectContext* cacheContext = [[NCCache sharedCache] managedObjectContext];
		[cacheContext performBlock:^{
			NCCacheRecord* cacheRecord = self.cache[key];
			if (!cacheRecord)
				self.cache[key] = cacheRecord = [NCCacheRecord cacheRecordWithRecordID:key];
			EVECorporationSheet* corporationSheet = cacheRecord.data.data;
			if (!corporationSheet) {
				[self.managedObjectContext performBlock:^{
					[[EVEOnlineAPI apiWithAPIKey:self.eveAPIKey cachePolicy:NSURLRequestUseProtocolCachePolicy] corporationSheetWithCorporationID:0
																																  completionBlock:^(EVECorporationSheet *result, NSError *error) {
																																	  [cacheContext performBlock:^{
																																		  [cacheRecord cacheResult:result];
																																	  }];
																																	  dispatch_async(dispatch_get_main_queue(), ^{
																																		  completionBlock(result, error);
																																		  if (result)
																																			  [[NSNotificationCenter defaultCenter] postNotificationName:NCAccountDidChangeNotification object:self userInfo:@{@"corporationSheet":result}];
																																		  
																																	  });
																																  }
																																	progressBlock:nil];
				}];
			}
			else {
				dispatch_async(dispatch_get_main_queue(), ^{
					completionBlock(corporationSheet, nil);
				});
			}
		}];
	}];
}

- (void) loadSkillQueueWithCompletionBlock:(void(^)(EVESkillQueue* skillQueue, NSError* error)) completionBlock {
	[self.managedObjectContext performBlock:^{
		NSString* key = [NSString stringWithFormat:@"%@.skillQueue", self.uuid];
		NSManagedObjectContext* cacheContext = [[NCCache sharedCache] managedObjectContext];
		[cacheContext performBlock:^{
			NCCacheRecord* cacheRecord = self.cache[key];
			if (!cacheRecord)
				self.cache[key] = cacheRecord = [NCCacheRecord cacheRecordWithRecordID:key];
			EVESkillQueue* skillQueue = cacheRecord.data.data;
			if (!skillQueue) {
				[self.managedObjectContext performBlock:^{
					[[EVEOnlineAPI apiWithAPIKey:self.eveAPIKey cachePolicy:NSURLRequestUseProtocolCachePolicy] skillQueueWithCompletionBlock:^(EVESkillQueue *result, NSError *error) {
						[cacheContext performBlock:^{
							[cacheRecord cacheResult:result];
						}];
						dispatch_async(dispatch_get_main_queue(), ^{
							if (result)
								[[NSNotificationCenter defaultCenter] postNotificationName:NCAccountDidChangeNotification object:self userInfo:@{@"skillQueue":result}];
							completionBlock(result, error);
						});
					}
																																progressBlock:nil];
				}];
			}
			else {
				dispatch_async(dispatch_get_main_queue(), ^{
					completionBlock(skillQueue, nil);
				});
			}
		}];
	}];
}

- (void) loadCharacterAttributesWithCompletionBlock:(void(^)(NCCharacterAttributes* characterAttributes, NSError* error)) completionBlock {
	NSString* key = @"characterAttributes";
	NCCharacterAttributes* attributes = self.cache[key];
	if (!attributes) {
		[self loadCharacterSheetWithCompletionBlock:^(EVECharacterSheet *characterSheet, NSError *error) {
			dispatch_async(dispatch_get_main_queue(), ^{
				if (characterSheet) {
					NCCharacterAttributes* attributes = [[NCCharacterAttributes alloc] initWithCharacterSheet:characterSheet];
					self.cache[key] = attributes;
					completionBlock(attributes, nil);
				}
				else
					completionBlock(nil, error);
			});
		}];
	}
	completionBlock(attributes, nil);
}

- (EVEAPIKey*) eveAPIKey {
	return [EVEAPIKey apiKeyWithKeyID:self.apiKey.keyID vCode:self.apiKey.vCode characterID:self.characterID corporate:self.accountType == NCAccountTypeCorporate];
}

- (void) reloadWithCachePolicy:(NSURLRequestCachePolicy) cachePolicy completionBlock:(void(^)(NSError* error)) completionBlock progressBlock:(void(^)(float progress)) progressBlock {
	[self.managedObjectContext performBlock:^{
		NSString* uuid = self.uuid;
		EVEOnlineAPI* api = [[EVEOnlineAPI alloc] initWithAPIKey:self.eveAPIKey cachePolicy:cachePolicy];
		
		[[[NCCache sharedCache] managedObjectContext] performBlock:^{
			NSDate* currentDate = [NSDate date];

			BOOL (^updateRequired)(NCCacheRecord*) = ^(NCCacheRecord* cacheRecord) {
				if (cachePolicy == NSURLRequestReloadIgnoringLocalCacheData)
					return YES;
				else if (cachePolicy == NSURLRequestReturnCacheDataElseLoad)
					return (BOOL) (cacheRecord.data.data != nil);
				else if (cachePolicy == NSURLRequestReturnCacheDataDontLoad)
					return NO;
				else
					return (BOOL)(!cacheRecord.data.data || !cacheRecord.expireDate || [cacheRecord.expireDate compare:currentDate] == NSOrderedAscending);
			};
			
			NCCacheRecord* (^loadCacheRecord)(NSString*) = ^(NSString* key) {
				NCCacheRecord* cacheRecord = self.cache[key];
				if (!cacheRecord)
					self.cache[key] = cacheRecord = [NCCacheRecord cacheRecordWithRecordID:key];
				return cacheRecord;
			};
			
			NSMutableArray* operations = [NSMutableArray new];

			__block EVECharacterInfo* characterInfo;
			__block EVECharacterSheet* characterSheet;
			__block EVECorporationSheet* corporationSheet;
			__block EVESkillQueue* skillQueue;

			NCCacheRecord* characterInfoCacheRecord = loadCacheRecord([NSString stringWithFormat:@"%@.characterInfo", uuid]);
			characterInfo = characterInfoCacheRecord.data.data;
			if (updateRequired(characterInfoCacheRecord))
				[operations addObject:[api characterInfoWithCharacterID:self.characterID completionBlock:nil progressBlock:nil]];
			
			NCCacheRecord* characterSheetCacheRecord = loadCacheRecord([NSString stringWithFormat:@"%@.characterSheet", uuid]);
			characterSheet = characterSheetCacheRecord.data.data;
			if (updateRequired(characterSheetCacheRecord))
				[operations addObject:[api characterSheetWithCompletionBlock:nil progressBlock:nil]];

			NCCacheRecord* corporationSheetCacheRecord = loadCacheRecord([NSString stringWithFormat:@"%@.corporationSheet", uuid]);
			corporationSheet = corporationSheetCacheRecord.data.data;
			if (updateRequired(corporationSheetCacheRecord))
				[operations addObject:[api corporationSheetWithCorporationID:0 completionBlock:nil progressBlock:nil]];
			
			NCCacheRecord* skillQueueCacheRecord = loadCacheRecord([NSString stringWithFormat:@"%@.skillQueue", uuid]);
			skillQueue = skillQueueCacheRecord.data.data;
			if (updateRequired(skillQueueCacheRecord))
				[operations addObject:[api characterSheetWithCompletionBlock:nil progressBlock:nil]];
			
			if (operations.count > 0) {
				[AFHTTPRequestOperation batchOfRequestOperations:operations
												   progressBlock:^void(NSUInteger numberOfFinishedOperations, NSUInteger totalNumberOfOperations) {
													   if (progressBlock)
														   progressBlock((float) totalNumberOfOperations / (float) numberOfFinishedOperations);
												   }
												 completionBlock:^void(NSArray * operations) {
													 NSError* error = nil;
													 for (AFHTTPRequestOperation* operation in operations) {
														 error = error ?: operation.error;
														 if ([operation.responseObject isKindOfClass:[EVECharacterInfo class]])
															 characterInfo = operation.responseObject;
														 else if ([operation.responseObject isKindOfClass:[EVECharacterSheet class]])
															 characterSheet = operation.responseObject;
														 else if ([operation.responseObject isKindOfClass:[EVECorporationSheet class]])
															 corporationSheet = operation.responseObject;
														 else if ([operation.responseObject isKindOfClass:[EVESkillQueue class]])
															 skillQueue = operation.responseObject;
													 }
													 
													 NSMutableDictionary* userInfo = [NSMutableDictionary new];
													 
													 if (characterSheet) {
														 if (characterInfo) {
															 int32_t skillPoints = 0;
															 for (EVECharacterSheetSkill* skill in characterSheet.skills)
																 skillPoints += skill.skillpoints;
															 characterInfo.skillPoints = skillPoints;
														 }
														 if (skillQueue)
															 [characterSheet attachSkillQueue:skillQueue];
													 }
													 
													 if (characterInfo)
														 userInfo[@"characterInfo"] = characterInfo;
													 if (characterSheet)
														 userInfo[@"characterSheet"] = characterSheet;
													 if (skillQueue)
														 userInfo[@"skillQueue"] = skillQueue;
													 if (corporationSheet)
														 userInfo[@"corporationSheet"] = corporationSheet;
													 
													 [[[NCCache sharedCache] managedObjectContext] performBlock:^{
														 for (NSString* item in @[@"characterInfo", @"characterSheet", @"skillQueue", @"corporationSheet"]) {
															 NSString* key = [NSString stringWithFormat:@"%@.%@", uuid, item];
															 NCCacheRecord* cacheRecord = self.cache[key];
															 if (!cacheRecord)
																 self.cache[key] = cacheRecord = [NCCacheRecord cacheRecordWithRecordID:key];
															 [cacheRecord cacheResult:userInfo[item]];
														 }
													 }];
													 
													 dispatch_async(dispatch_get_main_queue(), ^{
														 if (completionBlock)
															 completionBlock(error);
														 [[NSNotificationCenter defaultCenter] postNotificationName:NCAccountDidChangeNotification object:self userInfo:userInfo];
													 });
													 
												 }];
			}
		}];
	}];
}

#pragma mark - Private


@end
