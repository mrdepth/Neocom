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
@property (nonatomic, strong) NSManagedObjectContext* cacheManagedObjectContext;
@end

@implementation NCAccount

@dynamic characterID;
@dynamic order;
@dynamic apiKey;
@dynamic skillPlans;
@dynamic mailBox;
@dynamic uuid;

@synthesize cache = _cache;

@synthesize activeSkillPlan = _activeSkillPlan;
@synthesize cacheManagedObjectContext = _cacheManagedObjectContext;


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
			[account.managedObjectContext performBlock:^{
				NSString* uuid = account.uuid;
				dispatch_async(dispatch_get_main_queue(), ^{
					if (account)
						[[NSUserDefaults standardUserDefaults] setValue:uuid forKey:NCSettingsCurrentAccountKey];
					else
						[[NSUserDefaults standardUserDefaults] removeObjectForKey:NCSettingsCurrentAccountKey];
					[[NSUserDefaults standardUserDefaults] synchronize];
				});
			}];
		}
	}
	if (changed)
		[[NSNotificationCenter defaultCenter] postNotificationName:NCCurrentAccountDidChangeNotification object:account];
}

- (void) awakeFromInsert {
	[super awakeFromInsert];
	self.cache = [NSCache new];
	self.mailBox = [[NCMailBox alloc] initWithEntity:[NSEntityDescription entityForName:@"MailBox" inManagedObjectContext:self.managedObjectContext]
					  insertIntoManagedObjectContext:self.managedObjectContext];
}

- (void) awakeFromFetch {
	[super awakeFromFetch];
	[self uuid];
}

- (void) willSave {
	if ([self isDeleted]) {
		[self.cacheManagedObjectContext performBlock:^{
			NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
			NSEntityDescription *entity = [NSEntityDescription entityForName:@"Record" inManagedObjectContext:self.cacheManagedObjectContext];
			[fetchRequest setEntity:entity];
			[fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"recordID like %@", [NSString stringWithFormat:@"*%@*", self.uuid]]];

			NSArray *fetchedObjects = [self.cacheManagedObjectContext executeFetchRequest:fetchRequest error:nil];
			for (NCCacheRecord* record in fetchedObjects)
				[self.cacheManagedObjectContext deleteObject:record];

			[self.cacheManagedObjectContext save:nil];
		}];
	}
	
	[super willSave];
}

- (NCAccountType) accountType {
	return self.apiKey.apiKeyInfo.key.type == EVEAPIKeyTypeCorporation ? NCAccountTypeCorporate : NCAccountTypeCharacter;
}

- (NCSkillPlan*) activeSkillPlan {
	if (self.accountType == NCAccountTypeCharacter && (!_activeSkillPlan || [_activeSkillPlan isDeleted])) {
		if (self.skillPlans.count == 0) {
			_activeSkillPlan = [[NCSkillPlan alloc] initWithEntity:[NSEntityDescription entityForName:@"SkillPlan" inManagedObjectContext:self.managedObjectContext]
								   insertIntoManagedObjectContext:self.managedObjectContext];
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
		if ([self.managedObjectContext hasChanges])
			[self.managedObjectContext save:nil];
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
	if (activeSkillPlan) {
		dispatch_async(dispatch_get_main_queue(), ^{
			[[NSNotificationCenter defaultCenter] postNotificationName:NCAccountDidChangeActiveSkillPlanNotification object:self userInfo:@{NCAccountActiveSkillPlanKey:activeSkillPlan}];
		});
	}
}

- (void) loadCharacterInfoWithCompletionBlock:(void(^)(EVECharacterInfo* characterInfo, NSError* error)) completionBlock {
	void (^finalize)(EVECharacterInfo*, NSError* error) = ^(EVECharacterInfo* characterInfo, NSError* error){
		if (characterInfo) {
			[self loadCharacterSheetWithCompletionBlock:^(EVECharacterSheet *characterSheet, NSError *error2) {
				if (characterSheet) {
					int32_t skillPoints = 0;
					for (EVECharacterSheetSkill* skill in characterSheet.skills)
						skillPoints += skill.skillPoints;
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
				completionBlock(characterInfo, error);
			});
	};
	
	[self.managedObjectContext performBlock:^{
		NSString* key = [NSString stringWithFormat:@"%@.characterInfo", self.uuid];
		[self.cacheManagedObjectContext performBlock:^{
			NCCacheRecord* cacheRecord = self.cache[key];
			if (!cacheRecord)
				self.cache[key] = cacheRecord = [self.cacheManagedObjectContext cacheRecordWithRecordID:key];
			EVECharacterInfo* characterInfo = cacheRecord.data.data;
			if (!characterInfo) {
				[self.managedObjectContext performBlock:^{
					[[EVEOnlineAPI apiWithAPIKey:self.eveAPIKey cachePolicy:NSURLRequestUseProtocolCachePolicy] characterInfoWithCharacterID:self.characterID
																															 completionBlock:^(EVECharacterInfo *result, NSError *error) {
																																 [self.cacheManagedObjectContext performBlock:^{
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
		if (self.accountType == NCAccountTypeCharacter) {
			NSString* key = [NSString stringWithFormat:@"%@.characterSheet", self.uuid];
			[self.cacheManagedObjectContext performBlock:^{
				NCCacheRecord* cacheRecord = self.cache[key];
				if (!cacheRecord)
					self.cache[key] = cacheRecord = [self.cacheManagedObjectContext cacheRecordWithRecordID:key];
				EVECharacterSheet* characterSheet = cacheRecord.data.data;
				if (!characterSheet) {
					[self.managedObjectContext performBlock:^{
						[[EVEOnlineAPI apiWithAPIKey:self.eveAPIKey cachePolicy:NSURLRequestUseProtocolCachePolicy] characterSheetWithCompletionBlock:^(EVECharacterSheet *result, NSError *error) {
							[self.cacheManagedObjectContext performBlock:^{
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
		}
		else
			finalize(nil, [NSError errorWithDomain:EVEOnlineErrorDomain code:EVEErrorCodeInvalidAPIKeyType userInfo:@{NSLocalizedDescriptionKey:EVEErrorCodeInvalidAPIKeyTypeText}]);
	}];
}

- (void) loadCorporationSheetWithCompletionBlock:(void(^)(EVECorporationSheet* corporationSheet, NSError* error)) completionBlock {
	[self.managedObjectContext performBlock:^{
		if (self.accountType == NCAccountTypeCorporate) {
			NSString* key = [NSString stringWithFormat:@"%@.corporationSheet", self.uuid];
			[self.cacheManagedObjectContext performBlock:^{
				NCCacheRecord* cacheRecord = self.cache[key];
				if (!cacheRecord)
					self.cache[key] = cacheRecord = [self.cacheManagedObjectContext cacheRecordWithRecordID:key];
				EVECorporationSheet* corporationSheet = cacheRecord.data.data;
				if (!corporationSheet) {
					[self.managedObjectContext performBlock:^{
						[[EVEOnlineAPI apiWithAPIKey:self.eveAPIKey cachePolicy:NSURLRequestUseProtocolCachePolicy] corporationSheetWithCorporationID:0
																																	  completionBlock:^(EVECorporationSheet *result, NSError *error) {
																																		  [self.cacheManagedObjectContext performBlock:^{
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
		}
		else
			dispatch_async(dispatch_get_main_queue(), ^{
				completionBlock(nil, [NSError errorWithDomain:EVEOnlineErrorDomain code:EVEErrorCodeInvalidAPIKeyType userInfo:@{NSLocalizedDescriptionKey:EVEErrorCodeInvalidAPIKeyTypeText}]);
			});
	}];
}

- (void) loadSkillQueueWithCompletionBlock:(void(^)(EVESkillQueue* skillQueue, NSError* error)) completionBlock {
	[self.managedObjectContext performBlock:^{
		if (self.accountType == NCAccountTypeCharacter) {
			NSString* key = [NSString stringWithFormat:@"%@.skillQueue", self.uuid];
			[self.cacheManagedObjectContext performBlock:^{
				NCCacheRecord* cacheRecord = self.cache[key];
				if (!cacheRecord)
					self.cache[key] = cacheRecord = [self.cacheManagedObjectContext cacheRecordWithRecordID:key];
				EVESkillQueue* skillQueue = cacheRecord.data.data;
				if (!skillQueue) {
					[self.managedObjectContext performBlock:^{
						[[EVEOnlineAPI apiWithAPIKey:self.eveAPIKey cachePolicy:NSURLRequestUseProtocolCachePolicy] skillQueueWithCompletionBlock:^(EVESkillQueue *result, NSError *error) {
							[self.cacheManagedObjectContext performBlock:^{
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
		}
		else
			dispatch_async(dispatch_get_main_queue(), ^{
				completionBlock(nil, [NSError errorWithDomain:EVEOnlineErrorDomain code:EVEErrorCodeInvalidAPIKeyType userInfo:@{NSLocalizedDescriptionKey:EVEErrorCodeInvalidAPIKeyTypeText}]);
			});
	}];
}

- (void) loadFitCharacterWithCompletioBlock:(void(^)(NCFitCharacter* fitCharacter)) completionBlock {
	[self.managedObjectContext performBlock:^{
		NSString* key = [NSString stringWithFormat:@"%@.characterSheet", self.uuid];
		[self.cacheManagedObjectContext performBlock:^{
			NCCacheRecord* cacheRecord = self.cache[key];
			if (!cacheRecord)
				self.cache[key] = cacheRecord = [self.cacheManagedObjectContext cacheRecordWithRecordID:key];
			EVECharacterSheet* characterSheet = cacheRecord.data.data;
			if (characterSheet) {
				NCFitCharacter* character = [[NCFitCharacter alloc] initWithEntity:[NSEntityDescription entityForName:@"FitCharacter" inManagedObjectContext:self.managedObjectContext] insertIntoManagedObjectContext:nil];
				
				character.name = characterSheet.name;
				
				NSMutableDictionary* skills = [NSMutableDictionary new];
				for (EVECharacterSheetSkill* skill in characterSheet.skills)
					skills[@(skill.typeID)] = @(skill.level);
				character.skills = skills;
				
				NSMutableArray* implants = [NSMutableArray new];
				
				for (EVECharacterSheetImplant* implant in characterSheet.implants)
					[implants addObject:@(implant.typeID)];
				character.implants = implants;
				dispatch_async(dispatch_get_main_queue(), ^{
					completionBlock(character);
				});
			}
			else {
				dispatch_async(dispatch_get_main_queue(), ^{
					completionBlock(nil);
				});
			}
		}];
	}];
}

- (EVEAPIKey*) eveAPIKey {
	return [EVEAPIKey apiKeyWithKeyID:self.apiKey.keyID vCode:self.apiKey.vCode characterID:self.characterID corporate:self.accountType == NCAccountTypeCorporate];
}

- (void) reloadWithCachePolicy:(NSURLRequestCachePolicy) cachePolicy completionBlock:(void(^)(NSError* error)) completionBlock progressBlock:(void(^)(float progress)) progressBlock {
	[self.managedObjectContext performBlock:^{
		NSString* uuid = self.uuid;
		EVEOnlineAPI* api = [[EVEOnlineAPI alloc] initWithAPIKey:self.eveAPIKey cachePolicy:cachePolicy];
		int32_t characterID = self.characterID;
		NCAccountType accountType = self.accountType;
		
		[self.cacheManagedObjectContext performBlock:^{
			NSDate* currentDate = [NSDate date];
			__block NSError* lastError;

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
					self.cache[key] = cacheRecord = [self.cacheManagedObjectContext cacheRecordWithRecordID:key];
				return cacheRecord;
			};
			
			__block EVECharacterInfo* characterInfo;
			__block EVECharacterSheet* characterSheet;
			__block EVECorporationSheet* corporationSheet;
			__block EVESkillQueue* skillQueue;
			dispatch_group_t finishDispatchGroup = dispatch_group_create();

			NCCacheRecord* characterInfoCacheRecord = loadCacheRecord([NSString stringWithFormat:@"%@.characterInfo", uuid]);
			characterInfo = characterInfoCacheRecord.data.data;
			if (updateRequired(characterInfoCacheRecord)) {
				dispatch_group_enter(finishDispatchGroup);
				[api characterInfoWithCharacterID:characterID completionBlock:^(EVECharacterInfo *result, NSError *error) {
					if (error)
						lastError = error;
					characterInfo = result;
					dispatch_group_leave(finishDispatchGroup);
				} progressBlock:nil];
			}
			
			if (accountType == NCAccountTypeCharacter) {
				NCCacheRecord* characterSheetCacheRecord = loadCacheRecord([NSString stringWithFormat:@"%@.characterSheet", uuid]);
				characterSheet = characterSheetCacheRecord.data.data;
				if (updateRequired(characterSheetCacheRecord)) {
					dispatch_group_enter(finishDispatchGroup);
					[api characterSheetWithCompletionBlock:^(EVECharacterSheet *result, NSError *error) {
						characterSheet = result;
						dispatch_group_leave(finishDispatchGroup);
					} progressBlock:nil];
				}
				
				NCCacheRecord* skillQueueCacheRecord = loadCacheRecord([NSString stringWithFormat:@"%@.skillQueue", uuid]);
				skillQueue = skillQueueCacheRecord.data.data;
				if (updateRequired(skillQueueCacheRecord)) {
					dispatch_group_enter(finishDispatchGroup);
					[api skillQueueWithCompletionBlock:^(EVESkillQueue *result, NSError *error) {
						skillQueue = result;
						dispatch_group_leave(finishDispatchGroup);
					} progressBlock:nil];
				}
			}
			else {
				NCCacheRecord* corporationSheetCacheRecord = loadCacheRecord([NSString stringWithFormat:@"%@.corporationSheet", uuid]);
				corporationSheet = corporationSheetCacheRecord.data.data;
				if (updateRequired(corporationSheetCacheRecord)) {
					dispatch_group_enter(finishDispatchGroup);
					[api corporationSheetWithCorporationID:0 completionBlock:^(EVECorporationSheet *result, NSError *error) {
						corporationSheet = result;
						dispatch_group_leave(finishDispatchGroup);
					} progressBlock:nil];
				}
			}
			
			dispatch_group_notify(finishDispatchGroup, dispatch_get_main_queue(), ^{
				NSMutableDictionary* userInfo = [NSMutableDictionary new];
				
				if (characterSheet) {
					if (characterInfo) {
						int32_t skillPoints = 0;
						for (EVECharacterSheetSkill* skill in characterSheet.skills)
							skillPoints += skill.skillPoints;
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
				
				[self.cacheManagedObjectContext performBlock:^{
					for (NSString* item in @[@"characterInfo", @"characterSheet", @"skillQueue", @"corporationSheet"]) {
						//for (NSString* item in @[@"characterInfo", @"characterSheet", @"skillQueue"]) {
						NSString* key = [NSString stringWithFormat:@"%@.%@", uuid, item];
						NCCacheRecord* cacheRecord = self.cache[key];
						if (!cacheRecord)
							self.cache[key] = cacheRecord = [self.cacheManagedObjectContext cacheRecordWithRecordID:key];
						[cacheRecord cacheResult:userInfo[item]];
					}
				}];
				
				if (completionBlock)
					completionBlock(lastError);
				[[NSNotificationCenter defaultCenter] postNotificationName:NCAccountDidChangeNotification object:self userInfo:userInfo];
			});
		}];
	}];
}

- (NSManagedObjectContext*) cacheManagedObjectContext {
	if (!_cacheManagedObjectContext) {
		_cacheManagedObjectContext = [[NCCache sharedCache] createManagedObjectContext];
	}
	return _cacheManagedObjectContext;
}

#pragma mark - Private

- (NSCache*) cache {
	if (!_cache) {
		@synchronized(self) {
			if (!_cache)
				_cache = [NSCache new];
		}
	}
	return _cache;
}

@end
