//
//  EVEAccount.h
//  EVEUniverse
//
//  Created by Artem Shimanski on 9/2/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EVEOnlineAPI.h"
#import "EVEDBAPI.h"
#import "EVEAccountStorage.h"
#import "SkillPlan.h"
#import "EUMailBox.h"
#import "CharacterAttributes.h"
#import "APIKey.h"

@interface EVEAccount : NSObject
@property (nonatomic, strong) EVECharacterSheet *characterSheet;
@property (nonatomic, strong) EVESkillQueue *skillQueue;
@property (nonatomic, strong) NSMutableDictionary *properties;
@property (nonatomic, strong) SkillPlan* skillPlan;
@property (nonatomic, strong) EUMailBox *mailBox;

@property (nonatomic, strong) CharacterAttributes* characterAttributes;

@property (nonatomic, strong) NSArray* apiKeys;
@property (nonatomic, strong) APIKey* charAPIKey;
@property (nonatomic, strong) APIKey* corpAPIKey;
@property (nonatomic, strong) EVEAPIKeyInfoCharactersItem* character;
@property (nonatomic, assign, getter = isIgnored) BOOL ignored;
@property (nonatomic, strong) EVEAccountStatus* accountStatus;
@property (nonatomic, strong) EVECharacterInfo* characterInfo;

+ (EVEAccount*) dummyAccount;
+ (EVEAccount*) currentAccount;
+ (void) setCurrentAccount:(EVEAccount*) account;

- (void) login;
- (void) logoff;

- (void) reload;

- (void) updateSkillpoints;
@end
