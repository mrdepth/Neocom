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
#import "NCCharacterAttributes.h"
#import "NCAPIKey.h"
#import "NCMailBox.h"
#import "NCSkillPlan.h"

typedef NS_ENUM(NSInteger, NCAccountType) {
	NCAccountTypeCharacter,
	NCAccountTypeCorporate
};

@interface NCAccount : NSManagedObject

@property (nonatomic) int32_t characterID;
@property (nonatomic) int32_t order;
@property (nonatomic, strong) NCAPIKey *apiKey;
@property (nonatomic, strong) NSSet* skillPlans;
@property (nonatomic, strong) NCMailBox* mailBox;
@property (nonatomic, strong) NSString* uuid;

@property (nonatomic, strong) NCSkillPlan* activeSkillPlan;

@property (nonatomic, assign, readonly) NCAccountType accountType;

@property (nonatomic, strong, readonly) EVECharacterInfo* characterInfo;
@property (nonatomic, strong, readonly) EVECharacterSheet* characterSheet;
@property (nonatomic, strong, readonly) EVECorporationSheet* corporationSheet;
@property (nonatomic, strong, readonly) EVESkillQueue* skillQueue;

@property (nonatomic, strong, readonly) NCCharacterAttributes* characterAttributes;

@property (nonatomic, strong) NSError* error;

+ (NSArray*) allAccounts;
+ (instancetype) currentAccount;
+ (instancetype) accountWithUUID:(NSString*) uuid;
+ (void) setCurrentAccount:(NCAccount*) account;

- (BOOL) reloadWithCachePolicy:(NSURLRequestCachePolicy) cachePolicy error:(NSError**) errorPtr progressHandler:(void(^)(CGFloat progress, BOOL* stop)) progressHandler;

@end
