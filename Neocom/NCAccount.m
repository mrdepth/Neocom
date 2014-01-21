//
//  NCAccount.m
//  Neocom
//
//  Created by Admin on 04.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCAccount.h"
#import "NCStorage.h"
#import "NCAPIKey.h"
#import "NCCache.h"
#import "EVEDBInvType.h"

#define NCAccountSkillPointsUpdateInterval (60.0 * 10.0)

static NCAccount* currentAccount = nil;

@interface NCAccount()
@property (nonatomic, strong) NCCacheRecord* characterInfoCacheRecord;
@property (nonatomic, strong) NCCacheRecord* characterSheetCacheRecord;
@property (nonatomic, strong) NCCacheRecord* corporationSheetCacheRecord;
@property (nonatomic, strong) NCCacheRecord* skillQueueCacheRecord;

@property (nonatomic, strong, readwrite) EVECharacterInfo* characterInfo;
@property (nonatomic, strong, readwrite) EVECharacterSheet* characterSheet;
@property (nonatomic, strong, readwrite) EVECorporationSheet* corporationSheet;
@property (nonatomic, strong, readwrite) EVESkillQueue* skillQueue;

@property (nonatomic, strong) NSDate* lastSkillPointsUpdate;

@end

@implementation NCAccount

@dynamic characterID;
@dynamic order;
@dynamic apiKey;
@dynamic skillPlans;

@synthesize characterInfoCacheRecord = _characterInfoCacheRecord;
@synthesize characterSheetCacheRecord = _characterSheetCacheRecord;
@synthesize corporationSheetCacheRecord = _corporationSheetCacheRecord;
@synthesize skillQueueCacheRecord = _skillQueueCacheRecord;
@synthesize error = _error;
@synthesize characterAttributes = _characterAttributes;
@synthesize lastSkillPointsUpdate = _lastSkillPointsUpdate;
@synthesize activeSkillPlan = _activeSkillPlan;

+ (NSArray*) allAccounts {
	NCStorage* storage = [NCStorage sharedStorage];
	NSManagedObjectContext* context = storage.managedObjectContext;
	
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

+ (instancetype) currentAccount {
	@synchronized(self) {
		return currentAccount;
	}
}

+ (void) setCurrentAccount:(NCAccount*) account {
	@synchronized(self) {
		currentAccount = account;
		[[NSNotificationCenter defaultCenter] postNotificationName:NCAccountDidChangeNotification object:account];
		if (account) {
			[[NSUserDefaults standardUserDefaults] setURL:[account.objectID URIRepresentation] forKey:NCSettingsCurrentAccountKey];
		}
		else
			[[NSUserDefaults standardUserDefaults] removeObjectForKey:NCSettingsCurrentAccountKey];
		[[NSUserDefaults standardUserDefaults] synchronize];
	}
}

- (BOOL) reloadWithCachePolicy:(NSURLRequestCachePolicy) cachePolicy error:(NSError**) errorPtr progressHandler:(void(^)(CGFloat progress, BOOL* stop)) progressHandler {
	if ([NSThread isMainThread])
		return NO;
	
	__block BOOL shouldStop = NO;
	NSError* characterInfoError = nil;
	EVECharacterInfo* characterInfo = self.accountType == NCAccountTypeCharacter ? [EVECharacterInfo characterInfoWithKeyID:self.apiKey.keyID
																													  vCode:self.apiKey.vCode
																												cachePolicy:NSURLRequestUseProtocolCachePolicy
																												characterID:self.characterID
																													  error:&characterInfoError
																											progressHandler:^(CGFloat progress, BOOL *stop) {
																												if (progressHandler) {
																													progressHandler(progress / 4.0f, stop);
																													if (*stop)
																														shouldStop = YES;
																												}
																											}] : nil;
	
	if (shouldStop)
		return NO;
	
	NSError* characterSheetError = nil;
	EVECharacterSheet* characterSheet = self.accountType == NCAccountTypeCharacter ? [EVECharacterSheet characterSheetWithKeyID:self.apiKey.keyID
																														  vCode:self.apiKey.vCode
																													cachePolicy:cachePolicy
																													characterID:self.characterID
																														  error:&characterSheetError
																												progressHandler:^(CGFloat progress, BOOL *stop) {
																													if (progressHandler) {
																														progressHandler((1.0 + progress) / 4.0f, stop);
																														if (*stop)
																															shouldStop = YES;
																													}
																												}] : nil;
	
	if (shouldStop)
		return NO;
	
	NSError* corporationSheetError = nil;
	EVECorporationSheet* corporationSheet = [EVECorporationSheet corporationSheetWithKeyID:self.apiKey.keyID
																					 vCode:self.apiKey.vCode
																			   cachePolicy:cachePolicy
																			   characterID:self.characterID
																			 corporationID:0
																					 error:&corporationSheetError
																		   progressHandler:^(CGFloat progress, BOOL *stop) {
																			   if (progressHandler) {
																				   progressHandler((1.0 + progress) / 4.0f, stop);
																				   if (*stop)
																					   shouldStop = YES;
																			   }
																		   }];
	
	if (shouldStop)
		return NO;

	NSError* skillQueueError = nil;
	EVESkillQueue* skillQueue = self.accountType == NCAccountTypeCharacter ? [EVESkillQueue skillQueueWithKeyID:self.apiKey.keyID
																										  vCode:self.apiKey.vCode
																									cachePolicy:cachePolicy
																									characterID:self.characterID
																										  error:&skillQueueError
																								progressHandler:^(CGFloat progress, BOOL *stop) {
																									if (progressHandler) {
																										progressHandler((1.0 + progress) / 4.0f, stop);
																										if (*stop)
																											shouldStop = YES;
																									}
																								}] : nil;
	
	if (shouldStop)
		return NO;

	NCCache* cache = [NCCache sharedCache];
	[cache.managedObjectContext performBlockAndWait:^{
		if (characterInfo)
			self.characterInfo = characterInfo;
		else if (!self.characterSheetCacheRecord.data)
			self.characterInfo = (id) characterInfoError;
		
		if (characterSheet)
			self.characterSheet = characterSheet;
		else if (!self.characterSheetCacheRecord.data)
			self.characterSheet = (id) characterSheetError;
		
		if (corporationSheet)
			self.corporationSheet = corporationSheet;
		else if (!self.corporationSheetCacheRecord.data)
			self.corporationSheet = (id) corporationSheetError;
		
		if (skillQueue)
			self.skillQueue = skillQueue;
		else if (!self.skillQueueCacheRecord.data)
			self.skillQueue = (id) skillQueueError;
		[cache saveContext];
	}];
	
	if (errorPtr) {
		if (characterInfoError)
			*errorPtr = characterInfoError;
		else if (characterSheetError)
			*errorPtr = characterSheetError;
		else if (skillQueueError)
			*errorPtr = skillQueueError;
	}
	_characterAttributes = nil;
	self.lastSkillPointsUpdate = nil;
	return YES;
}

- (NCAccountType) accountType {
	return self.apiKey.apiKeyInfo.key.type == EVEAPIKeyTypeCorporation ? NCAccountTypeCorporate : NCAccountTypeCharacter;
}

- (EVECharacterInfo*) characterInfo {
	@synchronized(self) {
		if (!self.characterInfoCacheRecord.data)
			[self reloadWithCachePolicy:NSURLRequestUseProtocolCachePolicy error:nil progressHandler:nil];
		return [self.characterInfoCacheRecord.data isKindOfClass:[NSError class]] ? nil : self.characterInfoCacheRecord.data;
	}
}

- (EVECharacterSheet*) characterSheet {
	@synchronized(self) {
		if (!self.characterSheetCacheRecord.data)
			[self reloadWithCachePolicy:NSURLRequestUseProtocolCachePolicy error:nil progressHandler:nil];
		
		EVECharacterSheet* characterSheet = [self.characterSheetCacheRecord.data isKindOfClass:[NSError class]] ? nil : self.characterSheetCacheRecord.data;

		if (!_characterAttributes && characterSheet)
			_characterAttributes = [[NCCharacterAttributes alloc] initWithCharacterSheet:characterSheet];
		
		//Update skill points
		EVESkillQueue* skillQueue = self.skillQueue;
		if (characterSheet && skillQueue && (!self.lastSkillPointsUpdate || [self.lastSkillPointsUpdate timeIntervalSinceNow] < -NCAccountSkillPointsUpdateInterval)) {
			NCCharacterAttributes* characterAttributes = self.characterAttributes;
			NSDate *currentTime = [skillQueue serverTimeWithLocalTime:[NSDate date]];
			for (EVESkillQueueItem *item in skillQueue.skillQueue) {
				if (item.endTime && item.startTime) {
					EVECharacterSheetSkill *skill = characterSheet.skillsMap[@(item.typeID)];
					if (item.queuePosition == 0) {
						EVEDBInvType *type = [EVEDBInvType invTypeWithTypeID:item.typeID error:nil];
						skill.skillpoints = item.endSP - [item.endTime timeIntervalSinceDate:currentTime] * [characterAttributes skillpointsPerSecondForSkill:type];
					}
					else if (item.level - 1 == skill.level) {
						EVEDBInvType *type = [EVEDBInvType invTypeWithTypeID:item.typeID error:nil];
						skill.skillpoints = item.endSP - [item.endTime timeIntervalSinceDate:item.startTime] * [characterAttributes skillpointsPerSecondForSkill:type];
					}
				}
			}
			
			if (self.characterInfo) {
				NSInteger skillPoints = 0;
				for (EVECharacterSheetSkill* skill in characterSheet.skills)
					skillPoints += skill.skillpoints;
				self.characterInfo.skillPoints = skillPoints;
			}
			
			self.lastSkillPointsUpdate = [NSDate date];
			
			[self.activeSkillPlan updateSkillPoints];
		}
		
		return characterSheet;
	}
}

- (EVECorporationSheet*) corporationSheet {
	@synchronized(self) {
		if (!self.corporationSheetCacheRecord.data)
			[self reloadWithCachePolicy:NSURLRequestUseProtocolCachePolicy error:nil progressHandler:nil];
		return [self.corporationSheetCacheRecord.data isKindOfClass:[NSError class]] ? nil : self.corporationSheetCacheRecord.data;
	}
}

- (EVESkillQueue*) skillQueue {
	@synchronized(self) {
		if (!self.skillQueueCacheRecord.data)
			[self reloadWithCachePolicy:NSURLRequestUseProtocolCachePolicy error:nil progressHandler:nil];
		return [self.skillQueueCacheRecord.data isKindOfClass:[NSError class]] ? nil : self.skillQueueCacheRecord.data;
	}
}

- (void) setCharacterInfo:(EVECharacterInfo *)characterInfo {
	@synchronized(self) {
		self.characterInfoCacheRecord.data = characterInfo;
		if ([characterInfo isKindOfClass:[NSError class]]) {
			self.characterInfoCacheRecord.date = [NSDate date];
			self.characterInfoCacheRecord.expireDate = nil;
		}
		else {
			self.characterInfoCacheRecord.date = characterInfo.cacheDate;
			self.characterInfoCacheRecord.expireDate = characterInfo.cacheExpireDate;
		}
	}
}

- (void) setCharacterSheet:(EVECharacterSheet *)characterSheet {
	@synchronized(self) {
		self.characterSheetCacheRecord.data = characterSheet;
		if ([characterSheet isKindOfClass:[NSError class]]) {
			self.characterSheetCacheRecord.date = [NSDate date];
			self.characterSheetCacheRecord.expireDate = nil;
		}
		else {
			self.characterSheetCacheRecord.date = characterSheet.cacheDate;
			self.characterSheetCacheRecord.expireDate = characterSheet.cacheExpireDate;
		}
	}
}

- (void) setCorporationSheet:(EVECorporationSheet *)corporationSheet {
	@synchronized(self) {
		self.corporationSheetCacheRecord.data = corporationSheet;
		if ([corporationSheet isKindOfClass:[NSError class]]) {
			self.corporationSheetCacheRecord.date = [NSDate date];
			self.corporationSheetCacheRecord.expireDate = nil;
		}
		else {
			self.corporationSheetCacheRecord.date = corporationSheet.cacheDate;
			self.corporationSheetCacheRecord.expireDate = corporationSheet.cacheExpireDate;
		}
	}
}

- (void) setSkillQueue:(EVESkillQueue *)skillQueue {
	@synchronized(self) {
		self.skillQueueCacheRecord.data = skillQueue;
		if ([skillQueue isKindOfClass:[NSError class]]) {
			self.skillQueueCacheRecord.date = [NSDate date];
			self.skillQueueCacheRecord.expireDate = nil;
		}
		else {
			self.skillQueueCacheRecord.date = skillQueue.cacheDate;
			self.skillQueueCacheRecord.expireDate = skillQueue.cacheExpireDate;
		}
	}
}

- (NCSkillPlan*) activeSkillPlan {
	@synchronized(self) {
		if (!_activeSkillPlan) {
			__block NCSkillPlan* skillPlan = nil;

			NCStorage* storage = [NCStorage sharedStorage];
			[storage.managedObjectContext performBlockAndWait:^{
				if (self.skillPlans.count == 0) {
					skillPlan = [[NCSkillPlan alloc] initWithEntity:[NSEntityDescription entityForName:@"SkillPlan" inManagedObjectContext:self.managedObjectContext]
									 insertIntoManagedObjectContext:self.managedObjectContext];
					skillPlan.active = YES;
					skillPlan.account = self;
				}
				else {
					NSSet* skillPlans = [self.skillPlans filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"active == YES"]];
					if (skillPlans.count == 0) {
						skillPlan = [self.skillPlans anyObject];
						skillPlan.active = YES;
					}
					else if (skillPlans.count > 1) {
						NSMutableSet* set = [[NSMutableSet alloc] initWithSet:skillPlans];
						skillPlan = [set anyObject];
						[set removeObject:skillPlan];
						for (NCSkillPlan* item in set)
							item.active = NO;
					}
					else
						skillPlan = [skillPlans anyObject];
				}
				[storage saveContext];
			}];
			_activeSkillPlan = skillPlan;
		}
		return _activeSkillPlan;
	}
}

- (void) setActiveSkillPlan:(NCSkillPlan *)activeSkillPlan {
	@synchronized(self) {
		for (NCSkillPlan* skillPlan in self.skillPlans)
			skillPlan.active = NO;
		activeSkillPlan.active = YES;
	}
}

#pragma mark - Private

- (NCCacheRecord*) characterInfoCacheRecord {
	@synchronized(self) {
		if (!_characterInfoCacheRecord) {
			[[[NCCache sharedCache] managedObjectContext] performBlockAndWait:^{
				_characterInfoCacheRecord = [NCCacheRecord cacheRecordWithRecordID:[NSString stringWithFormat:@"%@.characterInfo", [[self objectID] URIRepresentation]]];
				[_characterInfoCacheRecord data];
			}];
		}
		return _characterInfoCacheRecord;
	}
}

- (NCCacheRecord*) characterSheetCacheRecord {
	@synchronized(self) {
		if (!_characterSheetCacheRecord) {
			[[[NCCache sharedCache] managedObjectContext] performBlockAndWait:^{
				_characterSheetCacheRecord = [NCCacheRecord cacheRecordWithRecordID:[NSString stringWithFormat:@"%@.characterSheet", [[self objectID] URIRepresentation]]];
				[_characterSheetCacheRecord data];
			}];
		}
		return _characterSheetCacheRecord;
	}
}

- (NCCacheRecord*) corporationSheetCacheRecord {
	@synchronized(self) {
		if (!_corporationSheetCacheRecord) {
			[[[NCCache sharedCache] managedObjectContext] performBlockAndWait:^{
				_corporationSheetCacheRecord = [NCCacheRecord cacheRecordWithRecordID:[NSString stringWithFormat:@"%@.corporationSheet", [[self objectID] URIRepresentation]]];
				[_corporationSheetCacheRecord data];
			}];
		}
		return _corporationSheetCacheRecord;
	}
}

- (NCCacheRecord*) skillQueueCacheRecord {
	@synchronized(self) {
		if (!_skillQueueCacheRecord) {
			[[[NCCache sharedCache] managedObjectContext] performBlockAndWait:^{
				_skillQueueCacheRecord = [NCCacheRecord cacheRecordWithRecordID:[NSString stringWithFormat:@"%@.skillQueue", [[self objectID] URIRepresentation]]];
				[_skillQueueCacheRecord data];
			}];
		}
		return _skillQueueCacheRecord;
	}
}

@end
