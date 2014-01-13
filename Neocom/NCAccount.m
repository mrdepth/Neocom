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
@property (nonatomic, strong) NCCacheRecord* characterSheetCacheRecord;
@property (nonatomic, strong) NCCacheRecord* corporationSheetCacheRecord;
@property (nonatomic, strong) NCCacheRecord* skillQueueCacheRecord;

@property (nonatomic, strong, readwrite) EVECharacterInfo* characterInfo;
@property (nonatomic, strong, readwrite) EVECharacterSheet* characterSheet;
@property (nonatomic, strong, readwrite) EVECorporationSheet* corporationSheet;
@property (nonatomic, strong, readwrite) EVESkillQueue* skillQueue;


@end

@implementation NCAccount

@dynamic characterID;
@dynamic order;
@dynamic apiKey;

@synthesize characterInfoCacheRecord = _characterInfoCacheRecord;
@synthesize characterSheetCacheRecord = _characterSheetCacheRecord;
@synthesize corporationSheetCacheRecord = _corporationSheetCacheRecord;
@synthesize skillQueueCacheRecord = _skillQueueCacheRecord;
@synthesize error = _error;

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
	}
}

- (BOOL) reloadWithCachePolicy:(NSURLRequestCachePolicy) cachePolicy error:(NSError**) errorPtr {
	if ([NSThread isMainThread])
		return NO;
	
	NSError* characterInfoError = nil;
	EVECharacterInfo* characterInfo = self.accountType == NCAccountTypeCharacter ? [EVECharacterInfo characterInfoWithKeyID:self.apiKey.keyID
																													  vCode:self.apiKey.vCode
																												cachePolicy:NSURLRequestUseProtocolCachePolicy
																												characterID:self.characterID
																													  error:&characterInfoError
																											progressHandler:nil] : nil;
	
	NSError* characterSheetError = nil;
	EVECharacterSheet* characterSheet = self.accountType == NCAccountTypeCharacter ? [EVECharacterSheet characterSheetWithKeyID:self.apiKey.keyID
																														  vCode:self.apiKey.vCode
																													cachePolicy:cachePolicy
																													characterID:self.characterID
																														  error:&characterSheetError
																												progressHandler:nil] : nil;
	
	NSError* corporationSheetError = nil;
	EVECorporationSheet* corporationSheet = [EVECorporationSheet corporationSheetWithKeyID:self.apiKey.keyID
																					 vCode:self.apiKey.vCode
																			   cachePolicy:cachePolicy
																			   characterID:self.characterID
																			 corporationID:0
																					 error:&corporationSheetError
																		   progressHandler:nil];
	
	NSError* skillQueueError = nil;
	EVESkillQueue* skillQueue = self.accountType == NCAccountTypeCharacter ? [EVESkillQueue skillQueueWithKeyID:self.apiKey.keyID
																										  vCode:self.apiKey.vCode
																									cachePolicy:cachePolicy
																									characterID:self.characterID
																										  error:&skillQueueError
																								progressHandler:nil] : nil;
	
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
