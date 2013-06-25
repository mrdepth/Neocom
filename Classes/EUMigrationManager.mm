//
//  EUMigrationManager.m
//  EVEUniverse
//
//  Created by Artem Shimanski on 04.02.13.
//
//

#import "EUMigrationManager.h"
#import "Globals.h"
#import "EUStorage.h"
#import "APIKey.h"
#import "IgnoredCharacter.h"
#import "ShipFit.h"
#import "POSFit.h"
#import "SkillPlan.h"

@interface EUMigrationManager()
- (void) migrateToVersion3;
- (void) migrateToVersion4;
- (void) migrateToVersion5;
- (void) migrateToVersion6;
- (void) migrateToVersion7;
@end


@implementation EUMigrationManager

- (void) migrateIfNeeded {
	NSInteger version = [[NSUserDefaults standardUserDefaults] integerForKey:@"version"];
	if (version < 3)
		[self migrateToVersion3];

	if (version < 4)
		[self migrateToVersion4];

	if (version < 5)
		[self migrateToVersion5];

	if (version < 6)
		[self migrateToVersion6];
	
	if (version < 7)
		[self migrateToVersion7];
}

#pragma mark - Private

- (void) migrateToVersion3 {
	NSFileManager* fileManager = [NSFileManager defaultManager];
	[fileManager removeItemAtPath:[Globals accountsFilePath] error:nil];
	NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
	[userDefaults setValue:nil forKey:SettingsCurrentAccount];
	[userDefaults setInteger:3 forKey:@"version"];
}

- (void) migrateToVersion4 {
	NSFileManager* fileManager = [NSFileManager defaultManager];
	NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
	NSString *directory = [documentsDirectory stringByAppendingPathComponent:@"EVEOnlineAPICache"];
	[fileManager removeItemAtPath:directory error:nil];
	
	directory = [documentsDirectory stringByAppendingPathComponent:@"URLImageViewCache"];
	[fileManager removeItemAtPath:directory error:nil];
	NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
	if ([userDefaults boolForKey:@"noAds"])
		[userDefaults setBool:YES forKey:SettingsNoAds];
	[userDefaults setInteger:4 forKey:@"version"];
}

- (void) migrateToVersion5 {
	NSFileManager* fileManager = [NSFileManager defaultManager];
	NSString* path = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"URLImageViewCache"];
	[fileManager removeItemAtPath:path error:nil];
	NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
	[userDefaults setInteger:5 forKey:@"version"];
}

- (void) migrateToVersion6 {
	NSString* documentsDirectory = [Globals documentsDirectory];
	NSArray* files = [[NSFileManager defaultManager] subpathsAtPath:documentsDirectory];
	for (NSString* file in files) {
		if ([file hasPrefix:@"skillPlan_"] && [[file pathExtension] isEqualToString:@"plist"]) {
			NSString* filePath = [documentsDirectory stringByAppendingPathComponent:file];
			NSMutableArray* skills = [NSMutableArray arrayWithContentsOfFile:filePath];
			NSMutableArray* output = [NSMutableArray array];
			for (NSDictionary* targetSkill in skills) {
				NSInteger typeID = [[targetSkill valueForKey:@"typeID"] integerValue];
				NSInteger requiredLevel = [[targetSkill valueForKey:@"level"] integerValue];
				for (NSInteger level = 1; level <= requiredLevel; level++) {
					BOOL found = NO;
					for (NSDictionary* skill in output) {
						if ([[skill valueForKey:@"typeID"] integerValue] == typeID && [[skill valueForKey:@"level"] integerValue] == level) {
							found = YES;
							break;
						}
					}
					if (!found) {
						NSDictionary* outputSkill = @{@"typeID" : @(typeID), @"level" : @(level)};
						[output addObject:outputSkill];
					}
				}
			}
			[output writeToFile:filePath atomically:YES];
		}
	}
	NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
	[userDefaults setInteger:6 forKey:@"version"];
}

- (void) migrateToVersion7 {
	EUStorage* storage = [EUStorage sharedStorage];

	NSDictionary* apiKeys = [NSDictionary dictionaryWithContentsOfFile:[Globals accountsFilePath]];
	
	for (NSDictionary* apiKey in [apiKeys valueForKey:@"apiKeys"]) {
		NSInteger keyID = [[apiKey valueForKey:@"keyID"] integerValue];
		NSString* vCode = [apiKey valueForKey:@"vCode"];
		if (!keyID || !vCode)
			continue;
		
		NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
		NSEntityDescription *entity = [NSEntityDescription entityForName:@"APIKey" inManagedObjectContext:storage.managedObjectContext];
		[fetchRequest setEntity:entity];
		
		NSPredicate *predicate = [NSPredicate predicateWithFormat:@"keyID = %d", keyID];
		[fetchRequest setPredicate:predicate];
		
		NSError *error = nil;
		NSArray *fetchedObjects = [storage.managedObjectContext executeFetchRequest:fetchRequest error:&error];
		if (fetchedObjects.count == 0) {
			APIKey* key = [[APIKey alloc] initWithEntity:entity insertIntoManagedObjectContext:storage.managedObjectContext];
			key.keyID = keyID;
			key.vCode = vCode;
		}
	}
	
	for (NSNumber* characterID in [apiKeys valueForKey:@"ignored"]) {
		NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
		NSEntityDescription *entity = [NSEntityDescription entityForName:@"IgnoredCharacter" inManagedObjectContext:storage.managedObjectContext];
		[fetchRequest setEntity:entity];
		
		NSPredicate *predicate = [NSPredicate predicateWithFormat:@"characterID = %@", characterID];
		[fetchRequest setPredicate:predicate];
		
		NSError *error = nil;
		NSArray *fetchedObjects = [storage.managedObjectContext executeFetchRequest:fetchRequest error:&error];
		if (fetchedObjects.count == 0) {
			IgnoredCharacter* ignoredCharacter = [[IgnoredCharacter alloc] initWithEntity:entity insertIntoManagedObjectContext:storage.managedObjectContext];
			ignoredCharacter.characterID = [characterID integerValue];
		}
	}
	
	[[NSFileManager defaultManager] removeItemAtPath:[Globals accountsFilePath] error:nil];

	
	NSArray* fits = [NSArray arrayWithContentsOfFile:[Globals fitsFilePath]];
	for (NSDictionary* fit in fits) {
		if ([[fit valueForKey:@"isPOS"] boolValue]) {
			NSString* fitName = [fit valueForKey:@"fitName"];
			NSString* imageName = [fit valueForKey:@"imageName"];
			NSInteger typeID = [[fit valueForKeyPath:@"fit.controlTowerID"] integerValue];
			NSString* typeName = [fit valueForKey:@"shipName"];
			
			
			NSMutableDictionary* structuresDic = [NSMutableDictionary dictionary];
			for (NSDictionary* structure in [fit valueForKeyPath:@"fit.structures"]) {
				NSInteger typeID = [[structure valueForKey:@"typeID"] integerValue];
				NSInteger chargeID = [[structure valueForKey: @"chargeID"] integerValue];
				NSInteger state = [[structure valueForKey:@"state"] integerValue];
				NSString* key = [NSString stringWithFormat:@"%d:%d:%d", typeID, state, chargeID];
				NSMutableDictionary* dic = [structuresDic valueForKey:key];
				if (!dic) {
					dic = [NSMutableDictionary dictionaryWithObjectsAndKeys:@(typeID), @"typeID", @(state), @"state", @(structuresDic.count), @"order", @(1), @"count", @(chargeID), @"chargeTypeID", nil];
					[structuresDic setValue:dic forKey:key];
				}
				else
					[dic setValue:@([[dic valueForKey:@"count"] integerValue] + 1) forKey:@"count"];
			}
			
			NSMutableArray* structures = [NSMutableArray array];
			for (NSDictionary* dic in [[structuresDic allValues] sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"order" ascending:YES]]]) {
				NSString* record = [NSString stringWithFormat:@"%d:%d:%d:%d",
									[[dic valueForKey:@"typeID"] integerValue],
									[[dic valueForKey:@"count"] integerValue],
									[[dic valueForKey:@"state"] integerValue],
									[[dic valueForKey:@"chargeTypeID"] integerValue]];
				[structures addObject:record];
			}
			
			NSString* structuresString = [structures componentsJoinedByString:@";"];
			
			POSFit* posFit = [[POSFit alloc] initWithEntity:[NSEntityDescription entityForName:@"POSFit" inManagedObjectContext:storage.managedObjectContext] insertIntoManagedObjectContext:storage.managedObjectContext];
			posFit.fitName = fitName;
			posFit.imageName = imageName;
			posFit.typeID = typeID;
			posFit.typeName = typeName;
			posFit.structures = structuresString;
		}
		else {
			NSDictionary* fitDetails = [fit valueForKey:@"fit"];
			NSString* fitName = [fit valueForKey:@"fitName"];
			NSString* imageName = [fit valueForKey:@"imageName"];
			NSInteger typeID = [[fitDetails valueForKey:@"shipID"] integerValue];
			NSString* typeName = [fit valueForKey:@"shipName"];

			NSMutableArray* hiSlots = [NSMutableArray array];
			NSMutableArray* medSlots = [NSMutableArray array];
			NSMutableArray* lowSlots = [NSMutableArray array];
			NSMutableArray* rigSlots = [NSMutableArray array];
			NSMutableArray* subsystems = [NSMutableArray array];
			NSMutableDictionary* dronesDic = [NSMutableDictionary dictionary];
			NSMutableArray* drones = [NSMutableArray array];
			NSMutableArray* implants = [NSMutableArray array];
			NSMutableArray* boosters = [NSMutableArray array];
			
			NSMutableArray* slots[] = {hiSlots, medSlots, lowSlots, rigSlots, subsystems};
			NSString* slotKeys[] = {@"highs", @"meds", @"lows", @"rigs", @"subsystems"};
			
			for (NSInteger i = 0; i < 5; i++) {
				for (NSDictionary* module in [fitDetails valueForKey:slotKeys[i]]) {
					NSInteger typeID = [[module valueForKey:@"typeID"] integerValue];
					NSInteger chargeID = [[module valueForKey: @"chargeID"] integerValue];
					NSInteger state = [[module valueForKey:@"state"] integerValue];
					NSString* record = [NSString stringWithFormat:@"%d:1:%d:%d", typeID, state, chargeID];
					[slots[i] addObject:record];
				}
			}
			
			for (NSDictionary* drone in [fitDetails valueForKey:@"drones"]) {
				NSInteger typeID = [[drone valueForKey:@"typeID"] integerValue];
				BOOL active = [[drone valueForKey:@"active"] boolValue];
				NSString* key = [NSString stringWithFormat:@"%d:%d", typeID, active];
				NSMutableDictionary* dic = [dronesDic valueForKey:key];
				if (!dic) {
					dic = [NSMutableDictionary dictionaryWithObjectsAndKeys:@(typeID), @"typeID", @(active), @"active", @(dronesDic.count), @"order", @(1), @"count", nil];
					[dronesDic setValue:dic forKey:key];
				}
				else
					[dic setValue:@([[dic valueForKey:@"count"] integerValue] + 1) forKey:@"count"];
			}
			
			for (NSDictionary* dic in [[dronesDic allValues] sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"order" ascending:YES]]]) {
				NSString* record = [NSString stringWithFormat:@"%d:%d:%d", [[dic valueForKey:@"typeID"] integerValue], [[dic valueForKey:@"count"] integerValue], [[dic valueForKey:@"active"] integerValue]];
				[drones addObject:record];
			}
			
			for (NSDictionary* implant in [fitDetails valueForKey:@"implants"]) {
				NSString* record = [NSString stringWithFormat:@"%d:1", [[implant valueForKey:@"typeID"] integerValue]];
				[implants addObject:record];
			}
			
			for (NSDictionary* booster in [fitDetails valueForKey:@"boosters"]) {
				NSString* record = [NSString stringWithFormat:@"%d:1", [[booster valueForKey:@"typeID"] integerValue]];
				[implants addObject:record];
			}
			
			NSString* hiSlotsString = [hiSlots componentsJoinedByString:@";"];
			NSString* medSlotsString = [medSlots componentsJoinedByString:@";"];
			NSString* lowSlotsString = [lowSlots componentsJoinedByString:@";"];
			NSString* rigSlotsString = [rigSlots componentsJoinedByString:@";"];
			NSString* subsystemsString = [subsystems componentsJoinedByString:@";"];
			NSString* dronesString = [drones componentsJoinedByString:@";"];
			NSString* implantsString = [implants componentsJoinedByString:@";"];
			NSString* boostersString = [boosters componentsJoinedByString:@";"];
			
			ShipFit* shipFit = [[ShipFit alloc] initWithEntity:[NSEntityDescription entityForName:@"ShipFit" inManagedObjectContext:storage.managedObjectContext] insertIntoManagedObjectContext:storage.managedObjectContext];

			shipFit.fitName = fitName;
			shipFit.imageName = imageName;
			shipFit.typeID = typeID;
			shipFit.typeName = typeName;
			shipFit.hiSlots = hiSlotsString;
			shipFit.medSlots = medSlotsString;
			shipFit.lowSlots = lowSlotsString;
			shipFit.rigSlots = rigSlotsString;
			shipFit.subsystems = subsystemsString;
			shipFit.drones = dronesString;
			shipFit.implants = implantsString;
			shipFit.boosters = boostersString;
		}
	}
	[[NSFileManager defaultManager] removeItemAtPath:[Globals fitsFilePath] error:nil];

	
	NSString* documentsDirectory = [Globals documentsDirectory];
	for (NSString* fileName in [[NSFileManager defaultManager] contentsOfDirectoryAtPath:documentsDirectory error:nil]) {
		if ([fileName hasPrefix:@"skillPlan_"]) {
			NSArray* components = [[fileName stringByDeletingPathExtension] componentsSeparatedByString:@"_"];
			if (components.count == 2) {
				NSInteger characterID = [[components objectAtIndex:1] integerValue];
				if (characterID) {
					NSString* filePath = [documentsDirectory stringByAppendingPathComponent:fileName];
					NSArray* array = [NSArray arrayWithContentsOfFile:filePath];
					NSMutableString* skills = [NSMutableString string];
					BOOL isFirst = YES;
					for (NSDictionary* skill in array) {
						NSInteger typeID = [[skill valueForKey:@"typeID"] integerValue];
						NSInteger level = [[skill valueForKey:@"level"] integerValue];
						if (isFirst) {
							[skills appendFormat:@"%d:%d", typeID, level];
							isFirst = NO;
						}
						else
							[skills appendFormat:@";%d:%d", typeID, level];
					}
					
					NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
					NSEntityDescription *entity = [NSEntityDescription entityForName:@"SkillPlan" inManagedObjectContext:storage.managedObjectContext];
					[fetchRequest setEntity:entity];
					
					NSPredicate *predicate = [NSPredicate predicateWithFormat:@"characterID = %d AND skillPlanName like \"main\"", characterID];
					[fetchRequest setPredicate:predicate];
					
					NSError *error = nil;
					NSArray *fetchedObjects = [storage.managedObjectContext executeFetchRequest:fetchRequest error:&error];

					SkillPlan* skillPlan = fetchedObjects.count > 0 ?
						[fetchedObjects objectAtIndex:0] :
						[[SkillPlan alloc] initWithEntity:[NSEntityDescription entityForName:@"SkillPlan" inManagedObjectContext:storage.managedObjectContext] insertIntoManagedObjectContext:storage.managedObjectContext];
					
					skillPlan.skillPlanName = @"main";
					skillPlan.skillPlanSkills = skills;
					skillPlan.characterID = characterID;
					[[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
				}
			}
		}
	}
	[storage saveContext];
	
	NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
	[userDefaults setInteger:7 forKey:@"version"];
}


@end
