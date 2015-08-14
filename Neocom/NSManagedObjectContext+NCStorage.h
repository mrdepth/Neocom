//
//  NSManagedObjectContext+NCStorage.h
//  Neocom
//
//  Created by Артем Шиманский on 14.08.15.
//  Copyright (c) 2015 Artem Shimanski. All rights reserved.
//

#import <CoreData/CoreData.h>

@class NCAccount;
@class NCFitCharacter;
@class NCSetting;
@class NCAPIKey;
@class NCShoppingList;
@interface NSManagedObjectContext (NCStorage)
//NCShoppingList
- (NSArray*) allShoppingLists;
- (NCShoppingList*) currentShoppingList;

//NCImplantSet
- (NSArray*) implantSets;

//NCDamagePattern
- (NSArray*) damagePatterns;

//NCLoadout
- (NSArray*) loadouts;
- (NSArray*) shipLoadouts;
- (NSArray*) posLoadouts;

//NCAccount
- (NSArray*) allAccounts;
- (NCAccount*) accountWithUUID:(NSString*) uuid;

//NCFitCharacter
- (NSArray*) characters;
- (NCFitCharacter*) characterWithAccount:(NCAccount*) account;
- (NCFitCharacter*) characterWithSkillsLevel:(NSInteger) skillsLevel;

//NCSetting
- (NCSetting*) settingWithKey:(NSString*) key;

//NCAPIKey
- (NCAPIKey*) apiKeyWithKeyID:(int32_t) keyID;
- (NSArray*) allAPIKeys;
@end
