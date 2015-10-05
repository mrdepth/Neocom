//
//  NSManagedObjectContext+NCStorage.m
//  Neocom
//
//  Created by Артем Шиманский on 14.08.15.
//  Copyright (c) 2015 Artem Shimanski. All rights reserved.
//

#import "NSManagedObjectContext+NCStorage.h"
#import "NCLoadout.h"
#import "NCFitCharacter.h"
#import "NCAccount.h"
#import "NCDatabase.h"
#import "NCSetting.h"
#import "NCShoppingList.h"

@implementation NSManagedObjectContext (NCStorage)

//NCShoppingList
- (NSArray*) allShoppingLists {
	NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"ShoppingList"];
	[fetchRequest setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]]];
	return [self executeFetchRequest:fetchRequest error:nil];
}

- (NCShoppingList*) currentShoppingList {
	NSString* urlString = [[NSUserDefaults standardUserDefaults] valueForKey:NCSettingsCurrentShoppingListKey];
	
	NCShoppingList* shoppingList;
	if (urlString) {
		NSURL* url = [NSURL URLWithString:urlString];
		if (url) {
			NSManagedObjectID* managedObjectID = [self.persistentStoreCoordinator managedObjectIDForURIRepresentation:url];
			if (managedObjectID)
				shoppingList = (NCShoppingList*) [self existingObjectWithID:managedObjectID error:nil];
		}
	}
	if (!shoppingList) {
		NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"ShoppingList"];
		request.fetchLimit = 1;
		shoppingList = [[self executeFetchRequest:request error:nil] lastObject];
		if (!shoppingList) {
			shoppingList = [[NCShoppingList alloc] initWithEntity:[NSEntityDescription entityForName:@"ShoppingList" inManagedObjectContext:self] insertIntoManagedObjectContext:self];
			shoppingList.name = NSLocalizedString(@"Default", nil);
			[self save:nil];
		}
	}
	return shoppingList;
}

//NCImplantSet
- (NSArray*) implantSets {
	NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"ImplantSet"];
	fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]];
	return [self executeFetchRequest:fetchRequest error:nil];
}

//NCDamagePattern
- (NSArray*) damagePatterns {
	NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"DamagePattern"];
	fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]];
	return [self executeFetchRequest:fetchRequest error:nil];
}

//NCLoadout
- (NSArray*) loadouts {
	NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Loadout"];
	NSArray* fetchedObjects = [self executeFetchRequest:fetchRequest error:nil];
	NSMutableArray* loadouts = [NSMutableArray new];
	
	for (NCLoadout* loadout in fetchedObjects) {
		if (!loadout.typeID)
			[self deleteObject:loadout];
		else
			[loadouts addObject:loadout];
	}
	if ([self hasChanges])
		[self save:nil];
	
	return loadouts;
}

/*- (NSArray*) shipLoadouts {
	return [[self loadouts] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"category == %d", NCLoadoutCategoryShip]];
}

- (NSArray*) posLoadouts {
	return [[self loadouts] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"category == %d", NCLoadoutCategoryPOS]];
}*/

//NCAccount
- (NSArray*) allAccounts {
	NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Account"];
	fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"order" ascending:YES],
									 [NSSortDescriptor sortDescriptorWithKey:@"characterID" ascending:YES]];
	
	return [self executeFetchRequest:fetchRequest error:nil];
}

- (NCAccount*) accountWithUUID:(NSString*) uuid {
	NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Account"];
	fetchRequest.predicate = [NSPredicate predicateWithFormat:@"uuid == %@", uuid];
	fetchRequest.fetchLimit = 1;
	return [[self executeFetchRequest:fetchRequest error:nil] lastObject];
}

//NCFitCharacter
- (NSArray*) characters {
	NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"FitCharacter"];
	fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]];
	return [self executeFetchRequest:fetchRequest error:nil];
}

/*- (NCFitCharacter*) characterWithAccount:(NCAccount*) account {
	if (!account)
		return nil;
	
	if (account.accountType == NCAccountTypeCorporate)
		return nil;
	
	NCFitCharacter* character = [[NCFitCharacter alloc] initWithEntity:[NSEntityDescription entityForName:@"FitCharacter" inManagedObjectContext:self] insertIntoManagedObjectContext:nil];
	
	character.name = localAccount.characterSheet.name;

	NSMutableDictionary* skills = [NSMutableDictionary new];
	for (EVECharacterSheetSkill* skill in localAccount.characterSheet.skills)
		skills[@(skill.typeID)] = @(skill.level);
	character.skills = skills;
	
	NSMutableArray* implants = [NSMutableArray new];
	
	for (EVECharacterSheetImplant* implant in account.characterSheet.implants)
		[implants addObject:@(implant.typeID)];
	character.implants = implants;
	
	return character;
}*/

- (NCFitCharacter*) characterWithSkillsLevel:(NSInteger) skillsLevel {
	NCFitCharacter* character = [[NCFitCharacter alloc] initWithEntity:[NSEntityDescription entityForName:@"FitCharacter" inManagedObjectContext:self] insertIntoManagedObjectContext:nil];
	character.name = [NSString stringWithFormat:NSLocalizedString(@"All Skills %d", nil), (int32_t) skillsLevel];
	
	NSManagedObjectContext* databaseManagedObjectContext = [[NCDatabase sharedDatabase] createManagedObjectContext];
	NSMutableDictionary* skills = [NSMutableDictionary new];

	[databaseManagedObjectContext performBlockAndWait:^{
		NSEntityDescription* entity = [NSEntityDescription entityForName:@"InvType" inManagedObjectContext:databaseManagedObjectContext];
		NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"InvType"];
		request.predicate = [NSPredicate predicateWithFormat:@"published == TRUE AND group.category.categoryID == 16"];
		request.resultType = NSDictionaryResultType;
		request.propertiesToFetch = @[entity.propertiesByName[@"typeID"]];
		for (NSDictionary* object in [databaseManagedObjectContext executeFetchRequest:request error:nil]) {
			skills[object[@"typeID"]] = @(skillsLevel);
		}
	}];
	character.skills = skills;
	
	return character;
}

//NCSetting
- (NCSetting*) settingWithKey:(NSString*) key {
	NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Setting"];
	fetchRequest.predicate = [NSPredicate predicateWithFormat:@"key == %@", key];
	fetchRequest.fetchLimit = 1;
	NCSetting* setting = [[self executeFetchRequest:fetchRequest error:nil] lastObject];
	if (!setting) {
		setting = [[NCSetting alloc] initWithEntity:[NSEntityDescription entityForName:@"Setting" inManagedObjectContext:self] insertIntoManagedObjectContext:self];
		setting.key = key;
	}

	
	return setting;
}

//NCAPIKey
- (NCAPIKey*) apiKeyWithKeyID:(int32_t) keyID {
	NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"APIKey"];
	fetchRequest.predicate = [NSPredicate predicateWithFormat:@"keyID == %d", keyID];
	fetchRequest.fetchLimit = 1;
	return [[self executeFetchRequest:fetchRequest error:nil] lastObject];
}

- (NSArray*) allAPIKeys {
	NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"APIKey"];
	return [self executeFetchRequest:fetchRequest error:nil];
}

@end
