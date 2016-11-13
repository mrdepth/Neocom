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
@import EVEAPI;

@implementation NCAccount

- (EVEAPIKey*) eveAPIKey {
	return [EVEAPIKey apiKeyWithKeyID:self.apiKey.keyID vCode:self.apiKey.vCode characterID:self.characterID corporate:self.apiKey.apiKeyInfo.key.type == EVEAPIKeyTypeCorporation];
}

@end
