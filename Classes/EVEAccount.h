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

@interface EVEAccount : NSObject
@property (nonatomic) NSInteger charKeyID;
@property (nonatomic, strong) NSString *charVCode;
@property (nonatomic) NSInteger charAccessMask;
@property (nonatomic) NSInteger corpKeyID;
@property (nonatomic, strong) NSString *corpVCode;
@property (nonatomic) NSInteger corpAccessMask;

@property (nonatomic) NSInteger characterID;
@property (nonatomic, strong) NSString *characterName;
@property (nonatomic) NSInteger corporationID;
@property (nonatomic, strong) NSString *corporationName;

@property (nonatomic, strong) EVECharacterSheet *characterSheet;
@property (nonatomic, strong) EVESkillQueue *skillQueue;
@property (nonatomic, strong) NSMutableDictionary *properties;
@property (nonatomic, strong) SkillPlan* skillPlan;
@property (nonatomic, strong) EUMailBox *mailBox;

@property (nonatomic, strong) CharacterAttributes* characterAttributes;


+ (EVEAccount*) accountWithCharacter:(EVEAccountStorageCharacter*) account;
+ (EVEAccount*) accountWithDictionary:(NSDictionary*) dictionary;
- (id) initWithDictionary:(NSDictionary*) dictionary;
- (id) initWithCharacter:(EVEAccountStorageCharacter*) account;

+ (EVEAccount*) dummyAccount;
+ (EVEAccount*) currentAccount;

- (void) login;
- (void) logoff;

+ (void) reload;

- (NSDictionary*) dictionary;

- (void) updateSkillpoints;
@end
