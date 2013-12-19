//
//  NCAccount.h
//  Neocom
//
//  Created by Artem Shimanski on 17.12.13.
//  Copyright (c) 2013 Artem Shimanski. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NCAPIKey.h"
#import "EVEOnlineAPI.h"

typedef enum {
	NCAccountTypeCharacter,
	NCAccountTypeCorporate
} NCAccountType;

@interface NCAccount : NSObject<NSCoding>
@property (nonatomic, strong) NCAPIKey* apiKey;
@property (nonatomic, assign, readonly) NCAccountType accountType;
@property (nonatomic, assign) NSInteger priority;
@property (nonatomic, assign, getter = isIgnored) BOOL ignored;

@property (nonatomic, strong) EVEAPIKeyInfoCharactersItem* character;
@property (nonatomic, strong) EVEAccountStatus* accountStatus;
@property (nonatomic, strong) EVECharacterInfo* characterInfo;
@property (nonatomic, strong) EVEAccountBalance* accountBalance;

@property (nonatomic, strong) NSError* error;

- (void) reload;

@end
