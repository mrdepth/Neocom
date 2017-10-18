//
//  NCMigrationManager.m
//  Neocom
//
//  Created by Артем Шиманский on 10.03.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCMigrationManager.h"
//#import "EUStorage.h"
//#import "ShipFit.h"
//#import "POSFit.h"
//#import "APIKey.h"
//#import "SkillPlan.h"
#import "NCAccountsManager.h"
#import "NCShipFit.h"
#import "NCPOSFit.h"
#import "NCStorage.h"
#import "NCDatabase.h"

@interface NCStorage()
- (void) notifyStorageChange;
@end


@interface NCMigrationManager()
@property (nonatomic, strong) NCStorage* storage;
@property (nonatomic, strong) NCAccountsManager* accountsManager;
@property (nonatomic, strong) id willChangeObserver;
@property (nonatomic, strong) id didChangeObserver;
@property (nonatomic, strong) id storeChangedObserver;

/*- (BOOL) transferAPIKeysWithError:(NSError**) errorPtr;
- (void) transferShipLoadouts;
- (void) transferPOSLoadouts;
- (void) transferSkillPlans;
- (void) transferCloudToLocal;*/
@end

@implementation NCMigrationManager

+ (BOOL) migrateWithError:(NSError**) errorPtr {
	NSFileManager* fileManager = [NSFileManager defaultManager];
	NSString* documents = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
	NSString* path = [documents stringByAppendingPathComponent:@"fallbackStore.sqlite"];
	NSError* error = nil;
	NCMigrationManager* migrationManager = [NCMigrationManager new];

	if ([fileManager fileExistsAtPath:path isDirectory:NULL]) {
//		migrationManager.storage = [NCStorage fallbackStorage];
		//migrationManager.accountsManager = [[NCAccountsManager alloc] initWithStorage:migrationManager.storage];
		@try {
//			[migrationManager transferAPIKeysWithError:&error];
//			[migrationManager transferShipLoadouts];
//			[migrationManager transferPOSLoadouts];
//			[migrationManager transferSkillPlans];
//			[migrationManager.storage.managedObjectContext performBlockAndWait:^{
//				[migrationManager.storage saveContext];
//			}];
		}
		@catch(NSException* exc) {
			
		}
	}
	
	@try {
	}
	@catch(NSException* exc) {
	}
	
	if (errorPtr)
		*errorPtr = error;
	
	if (!error) {
		for (NSString* fileName in [fileManager contentsOfDirectoryAtPath:documents error:nil]) {
			if ([fileName isEqualToString:@"Inbox"])
				continue;
			[fileManager removeItemAtPath:[documents stringByAppendingPathComponent:fileName] error:nil];
		}
	}
	
	return error == nil;
}

- (void) dealloc {
	
}

#pragma mark - Private

/*- (BOOL) transferAPIKeysWithError:(NSError**) errorPtr {
	NSFetchRequest *fetchRequest = [NSFetchRequest new];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"APIKey" inManagedObjectContext:self.oldStorage.managedObjectContext];
	[fetchRequest setEntity:entity];
	NSArray* apiKeys = [self.oldStorage.managedObjectContext executeFetchRequest:fetchRequest error:nil];
	NSMutableArray* invalidAPIKeys = [NSMutableArray new];
	NSError* error = nil;
	for (APIKey* apiKey in apiKeys) {
		if (![self.accountsManager addAPIKeyWithKeyID:apiKey.keyID vCode:apiKey.vCode error:&error]) {
			[invalidAPIKeys addObject:@(apiKey.keyID)];
		}
		else {
			[self.oldStorage.managedObjectContext deleteObject:apiKey];
		}
	}
	if (invalidAPIKeys.count > 0)
		error = [NSError errorWithDomain:@"Neocom"
									code:0
								userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:NSLocalizedString(@"Can't transfer api keys %@. Check your internet connection and try again.", nil), [invalidAPIKeys componentsJoinedByString:@", "]]}];
	
	if (errorPtr)
		*errorPtr = error;
	return error == nil;
}

- (void) transferShipLoadouts {
	NSFetchRequest* fetchRequest = [NSFetchRequest new];
	NSEntityDescription* entity = [NSEntityDescription entityForName:@"ShipFit" inManagedObjectContext:self.oldStorage.managedObjectContext];
	[fetchRequest setEntity:entity];
	NSArray* shipFits = [self.oldStorage.managedObjectContext executeFetchRequest:fetchRequest error:nil];
	
	for (ShipFit* shipFit in shipFits) {
		NCDBInvType* type = [NCDBInvType invTypeWithTypeID:shipFit.typeID];
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
						dgmpp::TypeID typeID = [[components objectAtIndex:0] intValue];
						if (typeID) {
							int modulesCount = numberOfComponents >= 2 ? [[components objectAtIndex:1] intValue] : 1;
							dgmpp::Module::State state = numberOfComponents >= 3 ? (dgmpp::Module::State) [[components objectAtIndex:2] integerValue] : dgmpp::Module::STATE_ONLINE;
							int32_t chargeTypeID = numberOfComponents >= 4 ? [[components objectAtIndex:3] intValue] : 0;
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
					dgmpp::TypeID typeID = [[components objectAtIndex:0] intValue];
					if (typeID) {
						int dronesCount = numberOfComponents >= 2 ? [[components objectAtIndex:1] intValue] : 1;
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
					dgmpp::TypeID typeID = [[components objectAtIndex:0] intValue];
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
					dgmpp::TypeID typeID = [[components objectAtIndex:0] intValue];
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
			
			
			[self.storage.managedObjectContext performBlockAndWait:^{
				NCLoadout* loadout = [[NCLoadout alloc] initWithEntity:[NSEntityDescription entityForName:@"Loadout" inManagedObjectContext:self.storage.managedObjectContext] insertIntoManagedObjectContext:self.storage.managedObjectContext];
				loadout.data = [[NCLoadoutData alloc] initWithEntity:[NSEntityDescription entityForName:@"LoadoutData" inManagedObjectContext:self.storage.managedObjectContext] insertIntoManagedObjectContext:self.storage.managedObjectContext];
				loadout.data.data = loadoutData;
				loadout.typeID = type.typeID;
				loadout.name = shipFit.fitName;
			}];
		}
		[self.oldStorage.managedObjectContext deleteObject:shipFit];
	}
}

- (void) transferPOSLoadouts {
	NSFetchRequest* fetchRequest = [NSFetchRequest new];
	NSEntityDescription* entity = [NSEntityDescription entityForName:@"POSFit" inManagedObjectContext:self.oldStorage.managedObjectContext];
	[fetchRequest setEntity:entity];
	NSArray* posFits = [self.oldStorage.managedObjectContext executeFetchRequest:fetchRequest error:nil];
	
	for (POSFit* posFit in posFits) {
		NSMutableArray* structures = [NSMutableArray new];
		for (NSString* row in [posFit.structures componentsSeparatedByString:@";"]) {
			NSArray* components = [row componentsSeparatedByString:@":"];
			NSInteger numberOfComponents = components.count;
			
			if (numberOfComponents >= 1) {
				dgmpp::TypeID typeID = [[components objectAtIndex:0] intValue];
				if (typeID) {
					int32_t count = numberOfComponents >= 2 ? [[components objectAtIndex:1] intValue] : 1;
					dgmpp::Module::State state = numberOfComponents >= 3 ? (dgmpp::Module::State) [[components objectAtIndex:2] intValue] : dgmpp::Module::STATE_ONLINE;
					int32_t chargeTypeID = numberOfComponents >= 4 ? [[components objectAtIndex:3] intValue] : 0;
					
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
		
		[self.storage.managedObjectContext performBlockAndWait:^{
			NCLoadoutDataPOS* loadoutData = [NCLoadoutDataPOS new];
			loadoutData.structures = structures;
			NCLoadout* loadout = [[NCLoadout alloc] initWithEntity:[NSEntityDescription entityForName:@"Loadout" inManagedObjectContext:self.storage.managedObjectContext] insertIntoManagedObjectContext:self.storage.managedObjectContext];
			loadout.data = [[NCLoadoutData alloc] initWithEntity:[NSEntityDescription entityForName:@"LoadoutData" inManagedObjectContext:self.storage.managedObjectContext] insertIntoManagedObjectContext:self.storage.managedObjectContext];
			loadout.data.data = loadoutData;
			loadout.typeID = posFit.typeID;
			loadout.name = posFit.fitName;
		}];
		[self.storage.managedObjectContext deleteObject:posFit];
	}
}

- (void) transferSkillPlans {
	NSFetchRequest* fetchRequest = [NSFetchRequest new];
	NSEntityDescription* entity = [NSEntityDescription entityForName:@"SkillPlan" inManagedObjectContext:self.oldStorage.managedObjectContext];
	[fetchRequest setEntity:entity];
	NSArray* skillPlans = [self.oldStorage.managedObjectContext executeFetchRequest:fetchRequest error:nil];
	
	for (SkillPlan* skillPlan in skillPlans) {
		BOOL transfered = NO;
		for (NCAccount* account in [self.accountsManager accounts]) {
			if (account.accountType == NCAccountTypeCharacter && account.characterID == skillPlan.characterID) {
				NCTrainingQueue* trainingQueue = [[NCTrainingQueue alloc] initWithAccount:account];
				for (NSString* row in [skillPlan.skillPlanSkills componentsSeparatedByString:@";"]) {
					NSArray* components = [row componentsSeparatedByString:@":"];
					if (components.count == 2) {
						int32_t typeID = [[components objectAtIndex:0] intValue];
						int32_t requiredLevel = [[components objectAtIndex:1] intValue];
						NCDBInvType* type = [NCDBInvType invTypeWithTypeID:typeID];
						if (type)
							[trainingQueue addSkill:type withLevel:requiredLevel];
					}
				}
				account.activeSkillPlan.trainingQueue = trainingQueue;
				transfered = YES;
			}
		}
		if (transfered)
			[self.oldStorage.managedObjectContext deleteObject:skillPlan];
	}
}

- (void) transferCloudToLocal {
	NSURL *sourceModelURL = [[NSBundle mainBundle] URLForResource:@"NCStorage.momd/NCStorage" withExtension:@"mom"];
	NSManagedObjectModel* sourceManagedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:sourceModelURL];
	
	NSURL* url = [[NSFileManager defaultManager] URLForUbiquityContainerIdentifier:nil];
	if (!url)
		return;
	
	NSString* directory = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES)[0] stringByAppendingPathComponent:@"com.shimanski.neocom.store"];
	NSString* backupDirectory = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES)[0] stringByAppendingPathComponent:@"com.shimanski.neocom.store.backup"];
	[[NSFileManager defaultManager] createDirectoryAtPath:backupDirectory withIntermediateDirectories:YES attributes:nil error:nil];
	[[NSFileManager defaultManager] createDirectoryAtPath:directory withIntermediateDirectories:YES attributes:nil error:nil];
	NSURL *storeURL = [NSURL fileURLWithPath:[backupDirectory stringByAppendingPathComponent:@"cloudStore.sqlite"]];
	NSURL *backupURL = [NSURL fileURLWithPath:[backupDirectory stringByAppendingPathComponent:@"backup.sqlite"]];
	
	
	void (^migrate)() = ^{
		dispatch_async(dispatch_get_main_queue(), ^{
			[[UIAlertView alertViewWithTitle:nil
									 message:NSLocalizedString(@"You need to update Neocom on all your devices to finish iCloud sync.", nil)
						   cancelButtonTitle:NSLocalizedString(@"Ok", nil)
						   otherButtonTitles:nil
							 completionBlock:nil
								 cancelBlock:nil] show];
		});

		void (^transfer)() = ^ {
			NCStorage* storage = [NCStorage sharedStorage];
			if (storage.allAccounts.count == 0 && storage.loadouts.count == 0) {
				NSPersistentStoreCoordinator* persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:storage.managedObjectModel];
				NSURL *storeURL = [NSURL fileURLWithPath:[directory stringByAppendingPathComponent:@"cloudStore.sqlite"]];
				
				if ([persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
															 configuration:@"Cloud"
																	   URL:backupURL
																   options:@{NSInferMappingModelAutomaticallyOption : @(YES),
																			 NSMigratePersistentStoresAutomaticallyOption : @(YES),
																			 NSPersistentStoreRemoveUbiquitousMetadataOption:@(YES)}
																	 error:nil]) {
					NSError* error = nil;
					if ([persistentStoreCoordinator migratePersistentStore:[persistentStoreCoordinator.persistentStores lastObject]
																	 toURL:storeURL
																   options:@{NSPersistentStoreUbiquitousContentNameKey : @"NCStorage",
																			 NSPersistentStoreUbiquitousContentURLKey : url,
																			 NSInferMappingModelAutomaticallyOption : @(YES),
																			 NSMigratePersistentStoresAutomaticallyOption : @(YES)}
																  withType:NSSQLiteStoreType
																	 error:&error]) {
						[storage removeDuplicatesFromPersistentStoreCoordinator:persistentStoreCoordinator];
						[storage notifyStorageChange];
					}
				}

				

				//[[NCStorage sharedStorage] restoreCloudData];
			}
			[[NSUserDefaults standardUserDefaults] setBool:YES forKey:NCSettingsDontNeedsCloudTransfer];
			[[NSUserDefaults standardUserDefaults] synchronize];
		};
		
		if (![NCStorage sharedStorage] || [NCStorage sharedStorage].storageType != NCStorageTypeCloud) {
			self.storeChangedObserver = [[NSNotificationCenter defaultCenter] addObserverForName:NCStorageDidChangeNotification
																						  object:nil
																						   queue:[NSOperationQueue mainQueue]
																					  usingBlock:^(NSNotification *note) {
																						  NCStorage* storage = note.object;
																						  if (storage.storageType == NCStorageTypeCloud) {
																							  [[NSNotificationCenter defaultCenter] removeObserver:self.storeChangedObserver];
																							  self.storeChangedObserver = nil;
																							  transfer();
																						  }
																					  }];
		}
		else {
			transfer();
		}
	};
	
	if (![[NSFileManager defaultManager] fileExistsAtPath:backupURL.path]) {
		NSPersistentStoreCoordinator* sourceCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:sourceManagedObjectModel];
		
		void (^didChange)(NSNotification*) = ^(NSNotification *note) {
			[[NSNotificationCenter defaultCenter] removeObserver:self.didChangeObserver];
			self.didChangeObserver = nil;

			if ([sourceCoordinator migratePersistentStore:[sourceCoordinator.persistentStores lastObject]
													toURL:backupURL
												  options:@{NSInferMappingModelAutomaticallyOption : @(YES),
															NSMigratePersistentStoresAutomaticallyOption : @(YES),
															NSPersistentStoreRemoveUbiquitousMetadataOption:@(YES)}
												 withType:NSSQLiteStoreType
													error:nil]) {
				migrate();
			}

			[[NSNotificationCenter defaultCenter] removeObserver:self.didChangeObserver];
			self.didChangeObserver = nil;
		};
		
		
		void (^willChange)(NSNotification*) = ^(NSNotification *note) {
			self.didChangeObserver = [[NSNotificationCenter defaultCenter] addObserverForName:NSPersistentStoreCoordinatorStoresDidChangeNotification
																					   object:sourceCoordinator
																						queue:[NSOperationQueue mainQueue]
																				   usingBlock:didChange];
			[[NSNotificationCenter defaultCenter] removeObserver:self.willChangeObserver];
			self.willChangeObserver = nil;
		};
		
		self.willChangeObserver = [[NSNotificationCenter defaultCenter] addObserverForName:NSPersistentStoreCoordinatorStoresWillChangeNotification
																					object:sourceCoordinator
																					 queue:[NSOperationQueue mainQueue]
																				usingBlock:willChange];
		
		if (![sourceCoordinator addPersistentStoreWithType:NSSQLiteStoreType
											 configuration:@"Cloud"
													   URL:storeURL
												   options:@{NSPersistentStoreUbiquitousContentNameKey : @"NCStorage",
															 NSPersistentStoreUbiquitousContentURLKey : url,
															 NSPersistentStoreRebuildFromUbiquitousContentOption:@(YES)}
													 error:nil]) {
			[[NSNotificationCenter defaultCenter] removeObserver:self.willChangeObserver];
			self.willChangeObserver = nil;
		}
	}
	else
		migrate();
}*/

@end
