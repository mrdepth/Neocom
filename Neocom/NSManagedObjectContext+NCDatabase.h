//
//  NSManagedObjectContext+NCDatabase.h
//  Neocom
//
//  Created by Артем Шиманский on 27.08.15.
//  Copyright (c) 2015 Artem Shimanski. All rights reserved.
//

#import <CoreData/CoreData.h>

typedef NS_ENUM(NSInteger, NCDBDgmppItemSlot) {
	NCDBDgmppItemSlotNone,
	NCDBDgmppItemSlotHi,
	NCDBDgmppItemSlotMed,
	NCDBDgmppItemSlotLow,
	NCDBDgmppItemSlotRig,
	NCDBDgmppItemSlotSubsystem,
	NCDBDgmppItemSlotStructure,
	NCDBDgmppItemSlotMode,
	NCDBDgmppItemSlotCharge,
	NCDBDgmppItemSlotDrone,
	NCDBDgmppItemSlotImplant,
	NCDBDgmppItemSlotBooster,
	NCDBDgmppItemSlotShip,
	NCDBDgmppItemSlotControlTower
};


@class NCDBEveIcon;
@class NCDBInvType;
@class NCDBDgmAttributeType;
@class NCDBInvGroup;
@class NCDBMapSolarSystem;
@class NCDBDgmppItemCategory;
@class NCDBChrRace;
@class NCDBStaStation;
@class NCDBMapDenormalize;
@class NCDBRamActivity;
@class NCDBMapRegion;
@class NCDBVersion;
@interface NSManagedObjectContext (NCDatabase)

//NCDBVersion
- (NCDBVersion*) version;

//NCDBEveIcon
- (NCDBEveIcon*) defaultTypeIcon;
- (NCDBEveIcon*) unknownTypeIcon;
- (NCDBEveIcon*) defaultGroupIcon;
- (NCDBEveIcon*) certificateUnclaimedIcon;
- (NCDBEveIcon*) eveIconWithIconFile:(NSString*) iconFile;


//NCDBInvType
- (NCDBInvType*) invTypeWithTypeID:(int32_t) typeID;
- (NCDBInvType*) invTypeWithTypeName:(NSString*) typeName;

//NCDBDgmAttributeType
- (NCDBDgmAttributeType*) dgmAttributeTypeWithAttributeTypeID:(int32_t) attributeTypeID;

//NCDBInvGroup
- (NCDBInvGroup*) invGroupWithGroupID:(int32_t) groupID;

//NCDBMapSolarSystem
- (NCDBMapSolarSystem*) mapSolarSystemWithName:(NSString*) name;
- (NCDBMapSolarSystem*) mapSolarSystemWithSolarSystemID:(int32_t) systemID;

//NCDBDgmppItemCategory
- (NCDBDgmppItemCategory*) shipsCategory;
- (NCDBDgmppItemCategory*) controlTowersCategory;
- (NCDBDgmppItemCategory*) categoryWithSlot:(NCDBDgmppItemSlot) slot size:(int32_t) size race:(NCDBChrRace*) race;

//NCDBStaStation
- (NCDBStaStation*) staStationWithStationID:(int32_t) stationID;

//NCDBMapDenormalize
- (NCDBMapDenormalize*) mapDenormalizeWithItemID:(int32_t) itemID;

//NCDBRamActivity
- (NCDBRamActivity*) ramActivityWithActivityID:(int32_t) activityID;

//NCDBMapRegion
- (NCDBMapRegion*) mapRegionWithRegionID:(int32_t) regionID;


@end
