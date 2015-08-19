//
//  NCAccount.h
//  Neocom
//
//  Created by Admin on 04.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import <EVEAPI/EVEAPI.h>
#import "NCCharacterAttributes.h"
#import "NCAPIKey.h"
#import "NCMailBox.h"
#import "NCSkillPlan.h"
#import "NCStorage.h"

#define NCSettingsCurrentAccountKey @"NCSettingsCurrentAccountKey"
#define NCCurrentAccountDidChangeNotification @"NCCurrentAccountDidChangeNotification"
#define NCAccountDidChangeNotification @"NCAccountDidChangeNotification"

typedef NS_ENUM(NSInteger, NCAccountType) {
	NCAccountTypeCharacter,
	NCAccountTypeCorporate
};

@interface NCStorage(NCAccount)
- (NSArray*) allAccounts;
- (NCAccount*) accountWithUUID:(NSString*) uuid;
@end

@interface NCAccount : NSManagedObject

@property (nonatomic) int32_t characterID;
@property (nonatomic) int32_t order;
@property (nonatomic, strong) NCAPIKey *apiKey;
@property (nonatomic, strong) NSSet* skillPlans;
@property (nonatomic, strong) NCMailBox* mailBox;
@property (nonatomic, strong) NSString* uuid;

@property (nonatomic, strong) NCSkillPlan* activeSkillPlan;

@property (nonatomic, assign, readonly) NCAccountType accountType;

@property (nonatomic, strong, readonly) EVEAPIKey* eveAPIKey;

+ (instancetype) currentAccount;
+ (void) setCurrentAccount:(NCAccount*) account;

- (void) loadCharacterInfoWithCompletionBlock:(void(^)(EVECharacterInfo* characterInfo, NSError* error)) completionBlock;
- (void) loadCharacterSheetWithCompletionBlock:(void(^)(EVECharacterSheet* characterSheet, NSError* error)) completionBlock;
- (void) loadCorporationSheetWithCompletionBlock:(void(^)(EVECorporationSheet* corporationSheet, NSError* error)) completionBlock;
- (void) loadSkillQueueWithCompletionBlock:(void(^)(EVESkillQueue* skillQueue, NSError* error)) completionBlock;
- (void) loadCharacterAttributesWithCompletionBlock:(void(^)(NCCharacterAttributes* characterAttributes, NSError* error)) completionBlock;
- (void) reloadWithCachePolicy:(NSURLRequestCachePolicy) cachePolicy completionBlock:(void(^)(NSError* error)) completionBlock progressBlock:(void(^)(float progress)) progressBlock;

@end
