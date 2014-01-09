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

static NCAccount* currentAccount = nil;

@interface NCAccount()
@property (nonatomic, strong) NCCacheRecord* characterInfoCacheRecord;
@property (nonatomic, strong) NCCacheRecord* accountBalanceCacheRecord;
@property (nonatomic, strong) NCCacheRecord* characterSheetCacheRecord;
@property (nonatomic, strong) NCCacheRecord* corporationSheetCacheRecord;
@property (nonatomic, strong) NCCacheRecord* skillQueueCacheRecord;

@property (nonatomic, strong, readwrite) EVECharacterInfo* characterInfo;
@property (nonatomic, strong, readwrite) EVEAccountBalance* accountBalance;
@property (nonatomic, strong, readwrite) EVECharacterSheet* characterSheet;
@property (nonatomic, strong, readwrite) EVECorporationSheet* corporationSheet;
@property (nonatomic, strong, readwrite) EVESkillQueue* skillQueue;


@end

@implementation NCAccount

@dynamic characterID;
@dynamic order;
@dynamic apiKey;

@synthesize characterInfoCacheRecord = _characterInfoCacheRecord;
@synthesize accountBalanceCacheRecord = _accountBalanceCacheRecord;
@synthesize characterSheetCacheRecord = _characterSheetCacheRecord;
@synthesize corporationSheetCacheRecord = _corporationSheetCacheRecord;
@synthesize skillQueueCacheRecord = _skillQueueCacheRecord;

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
	}
}

- (BOOL) reloadWithCachePolicy:(NSURLRequestCachePolicy) cachePolicy error:(NSError**) errorPtr {
	NSError* characterInfoError = nil;
	EVECharacterInfo* characterInfo = [EVECharacterInfo characterInfoWithKeyID:self.apiKey.keyID
																		 vCode:self.apiKey.vCode
																   cachePolicy:NSURLRequestUseProtocolCachePolicy
																   characterID:self.characterID
																		 error:&characterInfoError
															   progressHandler:nil];

	NSError* accountBalanceError = nil;
	EVEAccountBalance* accountBalance = [EVEAccountBalance accountBalanceWithKeyID:self.apiKey.keyID
																			 vCode:self.apiKey.vCode
																	   cachePolicy:cachePolicy
																	   characterID:self.characterID
																		 corporate:self.accountType == NCAccountTypeCorporate
																			 error:&accountBalanceError
																   progressHandler:nil];
	
	NSError* characterSheetError = nil;
	EVECharacterSheet* characterSheet = [EVECharacterSheet characterSheetWithKeyID:self.apiKey.keyID
																			 vCode:self.apiKey.vCode
																	   cachePolicy:cachePolicy
																	   characterID:self.characterID
																			 error:&characterSheetError
																   progressHandler:nil];

	NSError* corporationSheetError = nil;
	EVECorporationSheet* corporationSheet = [EVECorporationSheet corporationSheetWithKeyID:self.apiKey.keyID
																			 vCode:self.apiKey.vCode
																	   cachePolicy:cachePolicy
																	   characterID:self.characterID
																			 corporationID:0
																			 error:&corporationSheetError
																   progressHandler:nil];

	NSError* skillQueueError = nil;
	EVESkillQueue* skillQueue = [EVESkillQueue skillQueueWithKeyID:self.apiKey.keyID
															 vCode:self.apiKey.vCode
													   cachePolicy:cachePolicy
													   characterID:self.characterID
															 error:&skillQueueError
												   progressHandler:nil];
	
	NCCache* cache = [NCCache sharedCache];
	[cache.managedObjectContext performBlockAndWait:^{
		self.characterInfo = characterInfo ? characterInfo : (id) characterInfoError;
		self.accountBalance = accountBalance ? accountBalance : (id) accountBalanceError;
		self.characterSheet = characterSheet ? characterSheet : (id) characterSheetError;
		self.corporationSheet = corporationSheet ? corporationSheet : (id) corporationSheetError;
		self.skillQueue = skillQueue ? skillQueue : (id) skillQueueError;
		[cache saveContext];
	}];
	
	if (errorPtr) {
		if (characterInfoError)
			*errorPtr = characterInfoError;
		else if (accountBalanceError)
			*errorPtr = accountBalanceError;
		else if (characterSheetError)
			*errorPtr = characterSheetError;
		else if (skillQueueError)
			*errorPtr = skillQueueError;
	}
	return YES;
}

- (NCAccountType) accountType {
	return self.apiKey.apiKeyInfo.key.type == EVEAPIKeyTypeCorporation ? NCAccountTypeCorporate : NCAccountTypeCharacter;
}

- (EVECharacterInfo*) characterInfo {
	@synchronized(self) {
		if (!self.characterInfoCacheRecord.data)
			[self reloadWithCachePolicy:NSURLRequestUseProtocolCachePolicy error:nil];
		return [self.characterInfoCacheRecord.data isKindOfClass:[NSError class]] ? nil : self.characterInfoCacheRecord.data;
	}
}

- (EVEAccountBalance*) accountBalance {
	@synchronized(self) {
		if (!self.accountBalanceCacheRecord.data)
			[self reloadWithCachePolicy:NSURLRequestUseProtocolCachePolicy error:nil];
		return [self.accountBalanceCacheRecord.data isKindOfClass:[NSError class]] ? nil : self.accountBalanceCacheRecord.data;
	}
}

- (EVECharacterSheet*) characterSheet {
	@synchronized(self) {
		if (!self.characterSheetCacheRecord.data)
			[self reloadWithCachePolicy:NSURLRequestUseProtocolCachePolicy error:nil];
		return [self.characterSheetCacheRecord.data isKindOfClass:[NSError class]] ? nil : self.characterSheetCacheRecord.data;
	}
}

- (EVECorporationSheet*) corporationSheet {
	@synchronized(self) {
		if (!self.corporationSheetCacheRecord.data)
			[self reloadWithCachePolicy:NSURLRequestUseProtocolCachePolicy error:nil];
		return [self.corporationSheetCacheRecord.data isKindOfClass:[NSError class]] ? nil : self.corporationSheetCacheRecord.data;
	}
}

- (EVESkillQueue*) skillQueue {
	@synchronized(self) {
		if (!self.skillQueueCacheRecord.data)
			[self reloadWithCachePolicy:NSURLRequestUseProtocolCachePolicy error:nil];
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

- (void) setAccountBalance:(EVEAccountBalance *)accountBalance {
	@synchronized(self) {
		self.accountBalanceCacheRecord.data = accountBalance;
		if ([accountBalance isKindOfClass:[NSError class]]) {
			self.accountBalanceCacheRecord.date = [NSDate date];
			self.accountBalanceCacheRecord.expireDate = nil;
		}
		else {
			self.accountBalanceCacheRecord.date = accountBalance.cacheDate;
			self.accountBalanceCacheRecord.expireDate = accountBalance.cacheExpireDate;
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

#pragma mark - Private

- (NCCacheRecord*) characterInfoCacheRecord {
	@synchronized(self) {
		if (_characterInfoCacheRecord) {
			[[[NCCache sharedCache] managedObjectContext] performBlockAndWait:^{
				_characterInfoCacheRecord = [NCCacheRecord cacheRecordWithRecordID:[NSString stringWithFormat:@"%@.characterInfo", [[self objectID] URIRepresentation]]];
				[_characterInfoCacheRecord data];
			}];
		}
		return _characterInfoCacheRecord;
	}
}

- (NCCacheRecord*) accountBalanceCacheRecord {
	@synchronized(self) {
		if (_accountBalanceCacheRecord) {
			[[[NCCache sharedCache] managedObjectContext] performBlockAndWait:^{
				_accountBalanceCacheRecord = [NCCacheRecord cacheRecordWithRecordID:[NSString stringWithFormat:@"%@.accountBalance", [[self objectID] URIRepresentation]]];
				[_accountBalanceCacheRecord data];
			}];
		}
		return _accountBalanceCacheRecord;
	}
}

- (NCCacheRecord*) characterSheetCacheRecord {
	@synchronized(self) {
		if (_characterSheetCacheRecord) {
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
		if (_corporationSheetCacheRecord) {
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
		if (_skillQueueCacheRecord) {
			[[[NCCache sharedCache] managedObjectContext] performBlockAndWait:^{
				_skillQueueCacheRecord = [NCCacheRecord cacheRecordWithRecordID:[NSString stringWithFormat:@"%@.skillQueue", [[self objectID] URIRepresentation]]];
				[_skillQueueCacheRecord data];
			}];
		}
		return _skillQueueCacheRecord;
	}
}

@end
