//
//  NCAccount.m
//  Neocom
//
//  Created by Artem Shimanski on 12.11.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//  This file was automatically generated and should not be edited.
//

#import "NCAccount+CoreDataProperties.h"
#import "NCAPIKey+CoreDataClass.h"
#import "NCMailBox+CoreDataClass.h"
#import "NCSkillPlan+CoreDataClass.h"
#import "unitily.h"
@import EVEAPI;

static NCAccount* g_currentAccount;

@implementation NCAccount

- (EVEAPIKeyInfoCharactersItem*) character {
	return [[self.apiKey.apiKeyInfo.key.characters filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"characterID == %ld", (long) self.characterID]] lastObject];
}

- (EVEAPIKey*) eveAPIKey {
	return [EVEAPIKey apiKeyWithKeyID:self.apiKey.keyID vCode:self.apiKey.vCode characterID:self.characterID corporate:self.apiKey.apiKeyInfo.key.type == EVEAPIKeyTypeCorporation];
}

+ (instancetype) currentAccount {
	return g_currentAccount;
}

+ (void) setCurrentAccount:(NCAccount *)currentAccount {
	g_currentAccount = currentAccount;
	[[NSNotificationCenter defaultCenter] postNotificationName:NCCurrentAccountChangedNotification object:currentAccount];
}

@end
