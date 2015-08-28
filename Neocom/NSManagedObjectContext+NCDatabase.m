//
//  NSManagedObjectContext+NCDatabase.m
//  Neocom
//
//  Created by Артем Шиманский on 27.08.15.
//  Copyright (c) 2015 Artem Shimanski. All rights reserved.
//

#import "NSManagedObjectContext+NCDatabase.h"

@implementation NSManagedObjectContext (NCDatabase)

//NCDBEveIcon
- (NCDBEveIcon*) defaultTypeIcon {
	return [self eveIconWithIconFile:@"07_15"];
}

- (NCDBEveIcon*) defaultGroupIcon {
	return [self eveIconWithIconFile:@"38_174"];
}

- (NCDBEveIcon*) certificateUnclaimedIcon {
	return [self eveIconWithIconFile:@"79_01"];
}

- (NCDBEveIcon*) eveIconWithIconFile:(NSString*) iconFile {
	NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"EveIcon"];
	request.predicate = [NSPredicate predicateWithFormat:@"iconFile == %@", iconFile];
	request.fetchLimit = 1;
	return [[self executeFetchRequest:request error:nil] lastObject];
}


//NCDBInvType
- (NCDBInvType*) invTypeWithTypeID:(int32_t) typeID {
	NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"InvType"];
	request.predicate = [NSPredicate predicateWithFormat:@"typeID == %d", typeID];
	request.fetchLimit = 1;
	return [[self executeFetchRequest:request error:nil] lastObject];
}

- (NCDBInvType*) invTypeWithTypeName:(NSString*) typeName {
	if (!typeName)
		return nil;
	
	NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"InvType"];
	request.predicate = [NSPredicate predicateWithFormat:@"typeName LIKE[C] %@", typeName];
	request.fetchLimit = 1;
	return [[self executeFetchRequest:request error:nil] lastObject];
}

//NCDBDgmAttributeType
- (NCDBDgmAttributeType*) dgmAttributeTypeWithAttributeTypeID:(int32_t) attributeTypeID {
	NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"DgmAttributeType"];
	request.predicate = [NSPredicate predicateWithFormat:@"attributeID == %d", attributeTypeID];
	request.fetchLimit = 1;
	return [[self executeFetchRequest:request error:nil] lastObject];
}

//NCDBInvGroup
- (NCDBInvGroup*) invGroupWithGroupID:(int32_t) groupID {
	NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"InvGroup"];
	request.predicate = [NSPredicate predicateWithFormat:@"groupID == %d", groupID];
	request.fetchLimit = 1;
	return [[self executeFetchRequest:request error:nil] lastObject];
}

//NCDBMapSolarSystem
- (NCDBMapSolarSystem*) mapSolarSystemWithName:(NSString*) name {
	NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"MapSolarSystem"];
	request.predicate = [NSPredicate predicateWithFormat:@"solarSystemName == %@", name];
	request.fetchLimit = 1;
	return [[self executeFetchRequest:request error:nil] lastObject];
}

- (NCDBMapSolarSystem*) mapSolarSystemWithSolarSystemID:(int32_t) systemID {
	NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"MapSolarSystem"];
	request.predicate = [NSPredicate predicateWithFormat:@"solarSystemID == %d", systemID];
	request.fetchLimit = 1;
	return [[self executeFetchRequest:request error:nil] lastObject];
}

//NCDBEufeItemCategory
- (NCDBEufeItemCategory*) shipsCategory {
	return [self categoryWithSlot:NCDBEufeItemSlotShip size:0 race:nil];
}

- (NCDBEufeItemCategory*) controlTowersCategory {
	return [self categoryWithSlot:NCDBEufeItemSlotControlTower size:0 race:nil];
}

- (NCDBEufeItemCategory*) categoryWithSlot:(NCDBEufeItemSlot) slot size:(int32_t) size race:(NCDBChrRace*) race {
	NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"EufeItemCategory"];
	NSPredicate* predicate = [NSPredicate predicateWithFormat:@"category == %d", (int32_t) slot, size];
	if (size)
		predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[predicate, [NSPredicate predicateWithFormat:@"subcategory == %d", size]]];
	if (race)
		predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[predicate, [NSPredicate predicateWithFormat:@"race == %@", race]]];
	request.predicate = predicate;
	request.fetchLimit = 1;
	return [[self executeFetchRequest:request error:nil] lastObject];
}

//NCDBStaStation
- (NCDBStaStation*) staStationWithStationID:(int32_t) stationID {
	NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"StaStation"];
	request.predicate = [NSPredicate predicateWithFormat:@"stationID == %d", stationID];
	request.fetchLimit = 1;
	return [[self executeFetchRequest:request error:nil] lastObject];
}

//NCDBMapDenormalize
- (NCDBMapDenormalize*) mapDenormalizeWithItemID:(int32_t) itemID {
	NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"MapDenormalize"];
	request.predicate = [NSPredicate predicateWithFormat:@"itemID == %d", itemID];
	request.fetchLimit = 1;
	return [[self executeFetchRequest:request error:nil] lastObject];
}

//NCDBRamActivity
- (NCDBRamActivity*) ramActivityWithActivityID:(int32_t) activityID {
	NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"RamActivity"];
	request.predicate = [NSPredicate predicateWithFormat:@"activityID == %d", activityID];
	request.fetchLimit = 1;
	return [[self executeFetchRequest:request error:nil] lastObject];
}

//NCDBMapRegion
- (NCDBMapRegion*) mapRegionWithRegionID:(int32_t) regionID {
	NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"MapRegion"];
	request.predicate = [NSPredicate predicateWithFormat:@"regionID == %d", regionID];
	request.fetchLimit = 1;
	return [[self executeFetchRequest:request error:nil] lastObject];
}

@end
