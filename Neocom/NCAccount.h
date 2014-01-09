//
//  NCAccount.h
//  Neocom
//
//  Created by Admin on 04.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "EVEOnlineAPI.h"

typedef enum {
	NCAccountTypeCharacter,
	NCAccountTypeCorporate
} NCAccountType;

@class NCAPIKey;
@interface NCAccount : NSManagedObject

@property (nonatomic) int32_t characterID;
@property (nonatomic) int32_t order;
@property (nonatomic, retain) NCAPIKey *apiKey;

@property (nonatomic, assign, readonly) NCAccountType accountType;

@property (nonatomic, strong, readonly) EVECharacterInfo* characterInfo;
@property (nonatomic, strong, readonly) EVEAccountBalance* accountBalance;
@property (nonatomic, strong, readonly) EVECharacterSheet* characterSheet;
@property (nonatomic, strong, readonly) EVECorporationSheet* corporationSheet;
@property (nonatomic, strong, readonly) EVESkillQueue* skillQueue;

@property (nonatomic, strong) NSError* error;

+ (NSArray*) allAccounts;
+ (instancetype) currentAccount;
+ (void) setCurrentAccount:(NCAccount*) account;

- (BOOL) reloadWithCachePolicy:(NSURLRequestCachePolicy) cachePolicy error:(NSError**) errorPtr;

@end
