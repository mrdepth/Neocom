//
//  NCMigrationManager.m
//  Neocom
//
//  Created by Артем Шиманский on 10.03.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCMigrationManager.h"
#import "EUStorage.h"
#import "ShipFit.h"
#import "POSFit.h"
#import "APIKey.h"
#import "SkillPlan.h"
#import "NCAccountsManager.h"
#import "NCShipFit.h"
#import "NCPOSFit.h"
#import "NCStorage.h"

@interface NCMigrationManager()
+ (void) transferAPIKeysFromStorage:(EUStorage*) storage withError:(NSError**) errorPtr;
+ (void) transferShipLoadoutsFromStorage:(EUStorage*) storage;
+ (void) transferPOSLoadoutsFromStorage:(EUStorage*) storage;
+ (void) transferSkillPlansFromStorage:(EUStorage*) storage;
@end

@implementation NCMigrationManager

+ (BOOL) migrateWithError:(NSError**) errorPtr {
	NSFileManager* fileManager = [NSFileManager defaultManager];
	NSString* documents = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
	NSString* path = [documents stringByAppendingPathComponent:@"fallbackStore.sqlite"];
	NSError* error = nil;
	if ([fileManager fileExistsAtPath:path isDirectory:NULL]) {
		EUStorage* storage = [EUStorage new];
		[self transferAPIKeysFromStorage: storage withError:&error];
		[self transferShipLoadoutsFromStorage:storage];
		[self transferPOSLoadoutsFromStorage:storage];
		[self transferSkillPlansFromStorage:storage];
		NCStorage* ncStorage = [NCStorage sharedStorage];
		[ncStorage.managedObjectContext performBlockAndWait:^{
			[ncStorage saveContext];
		}];
		storage = nil;
	}
	if (errorPtr)
		*errorPtr = error;
	
	for (NSString* fileName in [fileManager contentsOfDirectoryAtPath:documents error:nil]) {
		[fileManager removeItemAtPath:[documents stringByAppendingPathComponent:fileName] error:nil];
	}
	return error == nil;
}

#pragma mark - Private

+ (void) transferAPIKeysFromStorage:(EUStorage*) storage withError:(NSError**) errorPtr {
	NSFetchRequest *fetchRequest = [NSFetchRequest new];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"APIKey" inManagedObjectContext:storage.managedObjectContext];
	[fetchRequest setEntity:entity];
	NSArray* apiKeys = [storage.managedObjectContext executeFetchRequest:fetchRequest error:nil];
	NSMutableArray* invalidAPIKeys = [NSMutableArray new];
	for (APIKey* apiKey in apiKeys) {
		NSError* error = nil;
		if (![[NCAccountsManager defaultManager] addAPIKeyWithKeyID:apiKey.keyID vCode:apiKey.vCode error:&error]) {
			[invalidAPIKeys addObject:@(apiKey.keyID)];
		}
		if (errorPtr && invalidAPIKeys.count > 0)
			*errorPtr = [NSError errorWithDomain:@"Neocom"
											code:0
										userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:NSLocalizedString(@"Can't transfer api keys %@", nil), [invalidAPIKeys componentsJoinedByString:@", "]]}];
	}
}

+ (void) transferShipLoadoutsFromStorage:(EUStorage*) storage {
	NSFetchRequest* fetchRequest = [NSFetchRequest new];
	NSEntityDescription* entity = [NSEntityDescription entityForName:@"ShipFit" inManagedObjectContext:storage.managedObjectContext];
	[fetchRequest setEntity:entity];
	NSArray* shipFits = [storage.managedObjectContext executeFetchRequest:fetchRequest error:nil];
	
	NCStorage* ncStorage = [NCStorage sharedStorage];
	
	for (ShipFit* shipFit in shipFits) {
		EVEDBInvType* type = [EVEDBInvType invTypeWithTypeID:shipFit.typeID error:nil];
		if (type) {
			NCLoadoutDataShip* loadoutData = [NCLoadoutDataShip new];
			
			NSMutableArray* hiSlots = [NSMutableArray new];
			NSMutableArray* medSlots = [NSMutableArray new];
			NSMutableArray* lowSlots = [NSMutableArray new];
			NSMutableArray* rigSlots = [NSMutableArray new];
			NSMutableArray* subsystems = [NSMutableArray new];
			NSMutableArray* drones = [NSMutableArray new];
			NSMutableArray* cargo = [NSMutableArray new];
			NSMutableArray* implants = [NSMutableArray new];
			NSMutableArray* boosters = [NSMutableArray new];
			
			NSArray* slotStrings = @[shipFit.hiSlots, shipFit.medSlots, shipFit.lowSlots, shipFit.rigSlots, shipFit.subsystems];
			NSArray* arrays = @[hiSlots, medSlots, lowSlots, rigSlots, subsystems];
			NSInteger n = slotStrings.count;
			
			for (NSInteger i = 0; i < n; i++) {
				NSString* slotString = [slotStrings objectAtIndex:i];
				NSMutableArray* array = [arrays objectAtIndex:i];
				
				for (NSString* row in [slotString componentsSeparatedByString:@";"]) {
					NSArray* components = [row componentsSeparatedByString:@":"];
					NSInteger numberOfComponents = components.count;
					
					if (numberOfComponents >= 1) {
						eufe::TypeID typeID = [[components objectAtIndex:0] integerValue];
						if (typeID) {
							NSInteger modulesCount = numberOfComponents >= 2 ? [[components objectAtIndex:1] integerValue] : 1;
							eufe::Module::State state = numberOfComponents >= 3 ? (eufe::Module::State) [[components objectAtIndex:2] integerValue] : eufe::Module::STATE_ONLINE;
							NSInteger chargeTypeID = numberOfComponents >= 4 ? [[components objectAtIndex:3] integerValue] : 0;
							NCLoadoutDataShipModule* module = [NCLoadoutDataShipModule new];
							module.typeID = typeID;
							module.chargeID = chargeTypeID;
							module.state = state;
							for (int j = 0; j < modulesCount; j++)
								[array addObject:module];
						}
					}
				}
			}
			
			
			for (NSString* row in [shipFit.drones componentsSeparatedByString:@";"]) {
				NSArray* components = [row componentsSeparatedByString:@":"];
				NSInteger numberOfComponents = components.count;
				
				if (numberOfComponents >= 1) {
					eufe::TypeID typeID = [[components objectAtIndex:0] integerValue];
					if (typeID) {
						NSInteger dronesCount = numberOfComponents >= 2 ? [[components objectAtIndex:1] integerValue] : 1;
						bool active = numberOfComponents >= 3 ? [[components objectAtIndex:2] boolValue] : true;
						NCLoadoutDataShipDrone* drone = [NCLoadoutDataShipDrone new];
						drone.typeID = typeID;
						drone.active = active;
						drone.count = dronesCount;
						[drones addObject:drone];
					}
				}
			}
			
			for (NSString* row in [shipFit.implants componentsSeparatedByString:@";"]) {
				NSArray* components = [row componentsSeparatedByString:@":"];
				NSInteger numberOfComponents = components.count;
				
				if (numberOfComponents >= 1) {
					eufe::TypeID typeID = [[components objectAtIndex:0] integerValue];
					if (typeID) {
						NCLoadoutDataShipImplant* implant = [NCLoadoutDataShipImplant new];
						implant.typeID = typeID;
						[implants addObject:implant];
					}
				}
			}
			
			for (NSString* row in [shipFit.boosters componentsSeparatedByString:@";"]) {
				NSArray* components = [row componentsSeparatedByString:@":"];
				NSInteger numberOfComponents = components.count;
				
				if (numberOfComponents >= 1) {
					eufe::TypeID typeID = [[components objectAtIndex:0] integerValue];
					if (typeID) {
						NCLoadoutDataShipBooster* booster = [NCLoadoutDataShipBooster new];
						booster.typeID = typeID;
						[boosters addObject:booster];
					}
				}
			}
			
			loadoutData.hiSlots = hiSlots;
			loadoutData.medSlots = medSlots;
			loadoutData.lowSlots = lowSlots;
			loadoutData.rigSlots = rigSlots;
			loadoutData.subsystems = subsystems;
			loadoutData.drones = drones;
			loadoutData.cargo = cargo;
			loadoutData.implants = implants;
			loadoutData.boosters = boosters;
			
			
			[ncStorage.managedObjectContext performBlockAndWait:^{
				NCLoadout* loadout = [[NCLoadout alloc] initWithEntity:[NSEntityDescription entityForName:@"Loadout" inManagedObjectContext:ncStorage.managedObjectContext] insertIntoManagedObjectContext:ncStorage.managedObjectContext];
				loadout.data = [[NCLoadoutData alloc] initWithEntity:[NSEntityDescription entityForName:@"LoadoutData" inManagedObjectContext:ncStorage.managedObjectContext] insertIntoManagedObjectContext:ncStorage.managedObjectContext];
				loadout.data.data = loadoutData;
				loadout.typeID = type.typeID;
				loadout.name = shipFit.fitName;
			}];
		}
	}
}

+ (void) transferPOSLoadoutsFromStorage:(EUStorage*) storage {
	NSFetchRequest* fetchRequest = [NSFetchRequest new];
	NSEntityDescription* entity = [NSEntityDescription entityForName:@"POSFit" inManagedObjectContext:storage.managedObjectContext];
	[fetchRequest setEntity:entity];
	NSArray* posFits = [storage.managedObjectContext executeFetchRequest:fetchRequest error:nil];
	
	NCStorage* ncStorage = [NCStorage sharedStorage];
	
	for (POSFit* posFit in posFits) {
		NSMutableArray* structures = [NSMutableArray new];
		for (NSString* row in [posFit.structures componentsSeparatedByString:@";"]) {
			NSArray* components = [row componentsSeparatedByString:@":"];
			NSInteger numberOfComponents = components.count;
			
			if (numberOfComponents >= 1) {
				eufe::TypeID typeID = [[components objectAtIndex:0] integerValue];
				if (typeID) {
					NSInteger count = numberOfComponents >= 2 ? [[components objectAtIndex:1] integerValue] : 1;
					eufe::Module::State state = numberOfComponents >= 3 ? (eufe::Module::State) [[components objectAtIndex:2] integerValue] : eufe::Module::STATE_ONLINE;
					NSInteger chargeTypeID = numberOfComponents >= 4 ? [[components objectAtIndex:3] integerValue] : 0;
					
					for (NSInteger i = 0; i < count; i++) {
						NCLoadoutDataPOSStructure* structure = [NCLoadoutDataPOSStructure new];
						structure.typeID = typeID;
						structure.count = count;
						structure.state = state;
						structure.chargeID = chargeTypeID;
						[structures addObject:structure];
					}
				}
			}
		}
		
		[ncStorage.managedObjectContext performBlockAndWait:^{
			NCLoadoutDataPOS* loadoutData = [NCLoadoutDataPOS new];
			loadoutData.structures = structures;
			NCLoadout* loadout = [[NCLoadout alloc] initWithEntity:[NSEntityDescription entityForName:@"Loadout" inManagedObjectContext:ncStorage.managedObjectContext] insertIntoManagedObjectContext:ncStorage.managedObjectContext];
			loadout.data = [[NCLoadoutData alloc] initWithEntity:[NSEntityDescription entityForName:@"LoadoutData" inManagedObjectContext:ncStorage.managedObjectContext] insertIntoManagedObjectContext:ncStorage.managedObjectContext];
			loadout.data.data = loadoutData;
			loadout.typeID = posFit.typeID;
			loadout.name = posFit.fitName;
		}];

	}
}

+ (void) transferSkillPlansFromStorage:(EUStorage*) storage {
	NSFetchRequest* fetchRequest = [NSFetchRequest new];
	NSEntityDescription* entity = [NSEntityDescription entityForName:@"SkillPlan" inManagedObjectContext:storage.managedObjectContext];
	[fetchRequest setEntity:entity];
	NSArray* skillPlans = [storage.managedObjectContext executeFetchRequest:fetchRequest error:nil];
	
	for (SkillPlan* skillPlan in skillPlans) {
		for (NCAccount* account in [[NCAccountsManager defaultManager] accounts]) {
			if (account.accountType == NCAccountTypeCharacter && account.characterID == skillPlan.characterID) {
				NCTrainingQueue* trainingQueue = [[NCTrainingQueue alloc] initWithAccount:account];
				for (NSString* row in [skillPlan.skillPlanSkills componentsSeparatedByString:@";"]) {
					NSArray* components = [row componentsSeparatedByString:@":"];
					if (components.count == 2) {
						NSInteger typeID = [[components objectAtIndex:0] integerValue];
						NSInteger requiredLevel = [[components objectAtIndex:1] integerValue];
						EVEDBInvType* type = [EVEDBInvType invTypeWithTypeID:typeID error:nil];
						if (type)
							[trainingQueue addSkill:type withLevel:requiredLevel];
					}
				}
				account.activeSkillPlan.trainingQueue = trainingQueue;
			}
		}
	}
}

@end
