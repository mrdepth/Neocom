//
//  NSManagedObjectContext+NCDatabase.m
//  Neocom
//
//  Created by Артем Шиманский on 27.08.15.
//  Copyright (c) 2015 Artem Shimanski. All rights reserved.
//

#import "NSManagedObjectContext+NCDatabase.h"
#import <objc/runtime.h>
#import "NCDatabase.h"

@interface NSManagedObjectContext (Cache)
@property (nonatomic, strong, readonly) NSMutableDictionary* invTypes;
@property (nonatomic, strong, readonly) NSMutableDictionary* invGroups;
@property (nonatomic, strong, readonly) NSMutableDictionary* eveIcons;
@property (nonatomic, strong, readonly) NSMutableDictionary* dgmppItemCategories;
@property (nonatomic, strong, readonly) NSMutableDictionary* staStations;
@property (nonatomic, strong, readonly) NSMutableDictionary* ramActivities;
@property (nonatomic, strong, readonly) NSMutableDictionary* mapRegions;
@property (nonatomic, strong, readonly) NSMutableDictionary* mapDenormalizes;
@property (nonatomic, strong, readonly) NSMutableDictionary* mapSolarSystems;
@property (nonatomic, strong, readonly) NSMutableDictionary* dgmAttributeTypes;
@end

@implementation NSManagedObjectContext (NCDatabase)

//NCDBVersion
- (NCDBVersion*) version {
	NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"Version"];
	request.fetchLimit = 1;
	return [[self executeFetchRequest:request error:nil] lastObject];
}

//NCDBEveIcon
- (NCDBEveIcon*) defaultTypeIcon {
	return [self eveIconWithIconFile:@"07_15"];
}

- (NCDBEveIcon*) unknownTypeIcon {
	return [self eveIconWithIconFile:@"07_14"];
}

- (NCDBEveIcon*) defaultGroupIcon {
	return [self eveIconWithIconFile:@"38_174"];
}

- (NCDBEveIcon*) certificateUnclaimedIcon {
	return [self eveIconWithIconFile:@"79_01"];
}

- (NCDBEveIcon*) eveIconWithIconFile:(NSString*) iconFile {
	if (!iconFile)
		return nil;
	
	NCDBEveIcon* icon = self.eveIcons[iconFile];
	if (!icon) {
		NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"EveIcon"];
		request.predicate = [NSPredicate predicateWithFormat:@"iconFile == %@", iconFile];
		request.fetchLimit = 1;
		icon = [[self executeFetchRequest:request error:nil] lastObject];
		if (icon)
			self.eveIcons[iconFile] = icon;
	}
	return icon;
}


//NCDBInvType
- (NCDBInvType*) invTypeWithTypeID:(int32_t) typeID {
	NCDBInvType* type = self.invTypes[@(typeID)];
	if (!type) {
		NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"InvType"];
		request.predicate = [NSPredicate predicateWithFormat:@"typeID == %d", typeID];
		request.fetchLimit = 1;
		type = [[self executeFetchRequest:request error:nil] lastObject];
		if (type)
			self.invTypes[@(typeID)] = type;
	}
	return type;
}

- (NCDBInvType*) invTypeWithTypeName:(NSString*) typeName {
	if (!typeName)
		return nil;

	NCDBInvType* type = self.invTypes[typeName];
	if (!type) {
		NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"InvType"];
		request.predicate = [NSPredicate predicateWithFormat:@"typeName LIKE[C] %@", typeName];
		request.fetchLimit = 1;
		type = [[self executeFetchRequest:request error:nil] lastObject];
		if (type)
			self.invTypes[typeName] = type;
	}
	return type;
}

//NCDBDgmAttributeType
- (NCDBDgmAttributeType*) dgmAttributeTypeWithAttributeTypeID:(int32_t) attributeTypeID {
	NCDBDgmAttributeType* attributeType = self.dgmAttributeTypes[@(attributeTypeID)];
	if (!attributeType) {
		NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"DgmAttributeType"];
		request.predicate = [NSPredicate predicateWithFormat:@"attributeID == %d", attributeTypeID];
		request.fetchLimit = 1;
		attributeType = [[self executeFetchRequest:request error:nil] lastObject];
		if (attributeType)
			self.dgmAttributeTypes[@(attributeTypeID)] = attributeType;
	}
	return attributeType;
}

//NCDBInvGroup
- (NCDBInvGroup*) invGroupWithGroupID:(int32_t) groupID {
	NCDBInvGroup* group = self.invGroups[@(groupID)];
	if (!group) {
		NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"InvGroup"];
		request.predicate = [NSPredicate predicateWithFormat:@"groupID == %d", groupID];
		request.fetchLimit = 1;
		group = [[self executeFetchRequest:request error:nil] lastObject];
		if (group)
			self.invGroups[@(groupID)] = group;
	}
	return group;
}

//NCDBMapSolarSystem
- (NCDBMapSolarSystem*) mapSolarSystemWithName:(NSString*) name {
	if (!name)
		return nil;
	
	NCDBMapSolarSystem* solarSystem = self.mapSolarSystems[name];
	if (!solarSystem) {
		NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"MapSolarSystem"];
		request.predicate = [NSPredicate predicateWithFormat:@"solarSystemName == %@", name];
		request.fetchLimit = 1;
		solarSystem = [[self executeFetchRequest:request error:nil] lastObject];
		if (solarSystem)
			self.mapSolarSystems[name] = solarSystem;
	}
	return solarSystem;
}

- (NCDBMapSolarSystem*) mapSolarSystemWithSolarSystemID:(int32_t) systemID {
	NCDBMapSolarSystem* solarSystem = self.mapSolarSystems[@(systemID)];
	if (!solarSystem) {
		NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"MapSolarSystem"];
		request.predicate = [NSPredicate predicateWithFormat:@"solarSystemID == %d", systemID];
		request.fetchLimit = 1;
		solarSystem = [[self executeFetchRequest:request error:nil] lastObject];
		if (solarSystem)
			self.mapSolarSystems[@(systemID)] = solarSystem;
	}
	return solarSystem;
}

//NCDBDgmppItemCategory
- (NCDBDgmppItemCategory*) shipsCategory {
	return [self categoryWithSlot:NCDBDgmppItemSlotShip size:0 race:nil];
}

- (NCDBDgmppItemCategory*) controlTowersCategory {
	return [self categoryWithSlot:NCDBDgmppItemSlotControlTower size:0 race:nil];
}

- (NCDBDgmppItemCategory*) categoryWithSlot:(NCDBDgmppItemSlot) slot size:(int32_t) size race:(NCDBChrRace*) race {
	int64_t key = ((((int64_t) size << 8) + slot) << 8) + race.raceID;

	NCDBDgmppItemCategory* itemCategory = self.dgmppItemCategories[@(key)];
	if (!itemCategory) {
		NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"DgmppItemCategory"];
		NSPredicate* predicate = [NSPredicate predicateWithFormat:@"category == %d", (int32_t) slot, size];
		if (size)
			predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[predicate, [NSPredicate predicateWithFormat:@"subcategory == %d", size]]];
		if (race)
			predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[predicate, [NSPredicate predicateWithFormat:@"race == %@", race]]];
		request.predicate = predicate;
		request.fetchLimit = 1;
		itemCategory = [[self executeFetchRequest:request error:nil] lastObject];
		if (itemCategory)
			self.dgmppItemCategories[@(key)] = itemCategory;
	}

	return itemCategory;
}

//NCDBStaStation
- (NCDBStaStation*) staStationWithStationID:(int32_t) stationID {
	NCDBStaStation* station = self.staStations[@(stationID)];
	if (!station) {
		NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"StaStation"];
		request.predicate = [NSPredicate predicateWithFormat:@"stationID == %d", stationID];
		request.fetchLimit = 1;
		station = [[self executeFetchRequest:request error:nil] lastObject];
		if (station)
			self.staStations[@(stationID)] = station;
	}
	return station;
}

//NCDBMapDenormalize
- (NCDBMapDenormalize*) mapDenormalizeWithItemID:(int32_t) itemID {
	NCDBMapDenormalize* item = self.mapDenormalizes[@(itemID)];
	if (!item) {
		NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"MapDenormalize"];
		request.predicate = [NSPredicate predicateWithFormat:@"itemID == %d", itemID];
		request.fetchLimit = 1;
		item = [[self executeFetchRequest:request error:nil] lastObject];
		if (item)
			self.mapDenormalizes[@(itemID)] = item;
	}
	return item;
}

//NCDBRamActivity
- (NCDBRamActivity*) ramActivityWithActivityID:(int32_t) activityID {
	NCDBRamActivity* activity = self.ramActivities[@(activityID)];
	if (!activity) {
		NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"RamActivity"];
		request.predicate = [NSPredicate predicateWithFormat:@"activityID == %d", activityID];
		request.fetchLimit = 1;
		activity = [[self executeFetchRequest:request error:nil] lastObject];
		if (activity)
			self.ramActivities[@(activityID)] = activity;
	}
	return activity;
}

//NCDBMapRegion
- (NCDBMapRegion*) mapRegionWithRegionID:(int32_t) regionID {
	NCDBMapRegion* region = self.mapRegions[@(regionID)];
	if (!region) {
		NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"MapRegion"];
		request.predicate = [NSPredicate predicateWithFormat:@"regionID == %d", regionID];
		request.fetchLimit = 1;
		region = [[self executeFetchRequest:request error:nil] lastObject];
		if (region)
			self.mapRegions[@(regionID)] = region;
	}
	return region;
}

#pragma mark - Cache

- (NSMutableDictionary*) invTypes {
	NSMutableDictionary* invTypes = objc_getAssociatedObject(self, @"invTypes");
	if (!invTypes) {
		invTypes = [NSMutableDictionary new];
		objc_setAssociatedObject(self, @"invTypes", invTypes, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	}
	return invTypes;
}

- (NSMutableDictionary*) invGroups {
	NSMutableDictionary* invGroups = objc_getAssociatedObject(self, @"invGroups");
	if (!invGroups) {
		invGroups = [NSMutableDictionary new];
		objc_setAssociatedObject(self, @"invGroups", invGroups, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	}
	return invGroups;
}

- (NSMutableDictionary*) eveIcons {
	NSMutableDictionary* eveIcons = objc_getAssociatedObject(self, @"eveIcons");
	if (!eveIcons) {
		eveIcons = [NSMutableDictionary new];
		objc_setAssociatedObject(self, @"eveIcons", eveIcons, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	}
	return eveIcons;
}

- (NSMutableDictionary*) dgmppItemCategories {
	NSMutableDictionary* dgmppItemCategories = objc_getAssociatedObject(self, @"dgmppItemCategories");
	if (!dgmppItemCategories) {
		dgmppItemCategories = [NSMutableDictionary new];
		objc_setAssociatedObject(self, @"dgmppItemCategories", dgmppItemCategories, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	}
	return dgmppItemCategories;
}

- (NSMutableDictionary*) staStations {
	NSMutableDictionary* staStations = objc_getAssociatedObject(self, @"staStations");
	if (!staStations) {
		staStations = [NSMutableDictionary new];
		objc_setAssociatedObject(self, @"staStations", staStations, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	}
	return staStations;
}

- (NSMutableDictionary*) ramActivities {
	NSMutableDictionary* ramActivities = objc_getAssociatedObject(self, @"ramActivities");
	if (!ramActivities) {
		ramActivities = [NSMutableDictionary new];
		objc_setAssociatedObject(self, @"ramActivities", ramActivities, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	}
	return ramActivities;
}

- (NSMutableDictionary*) mapRegions {
	NSMutableDictionary* mapRegions = objc_getAssociatedObject(self, @"mapRegions");
	if (!mapRegions) {
		mapRegions = [NSMutableDictionary new];
		objc_setAssociatedObject(self, @"mapRegions", mapRegions, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	}
	return mapRegions;
}

- (NSMutableDictionary*) mapDenormalizes {
	NSMutableDictionary* mapDenormalizes = objc_getAssociatedObject(self, @"mapDenormalizes");
	if (!mapDenormalizes) {
		mapDenormalizes = [NSMutableDictionary new];
		objc_setAssociatedObject(self, @"mapDenormalizes", mapDenormalizes, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	}
	return mapDenormalizes;
}

- (NSMutableDictionary*) mapSolarSystems {
	NSMutableDictionary* mapSolarSystems = objc_getAssociatedObject(self, @"mapSolarSystems");
	if (!mapSolarSystems) {
		mapSolarSystems = [NSMutableDictionary new];
		objc_setAssociatedObject(self, @"mapSolarSystems", mapSolarSystems, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	}
	return mapSolarSystems;
}

- (NSMutableDictionary*) dgmAttributeTypes {
	NSMutableDictionary* dgmAttributeTypes = objc_getAssociatedObject(self, @"dgmAttributeTypes");
	if (!dgmAttributeTypes) {
		dgmAttributeTypes = [NSMutableDictionary new];
		objc_setAssociatedObject(self, @"dgmAttributeTypes", dgmAttributeTypes, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	}
	return dgmAttributeTypes;
}

@end
