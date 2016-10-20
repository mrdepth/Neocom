//
//  NCAccount+CoreDataClass.m
//  Develop
//
//  Created by Artem Shimanski on 18.10.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCAccount+CoreDataClass.h"
#import "NCAPIKey+CoreDataClass.h"
#import "NCMailBox+CoreDataClass.h"
#import "NCSkillPlan+CoreDataClass.h"
@import EVEAPI;

@implementation NCAccount

- (EVEAPIKey*) eveAPIKey {
	return [EVEAPIKey apiKeyWithKeyID:self.apiKey.keyID vCode:self.apiKey.vCode characterID:self.characterID corporate:self.apiKey.apiKeyInfo.key.type == EVEAPIKeyTypeCorporation];
}

@end
