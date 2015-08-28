//
//  NSManagedObjectContext+NCDatabase.h
//  Neocom
//
//  Created by Артем Шиманский on 27.08.15.
//  Copyright (c) 2015 Artem Shimanski. All rights reserved.
//

#import <CoreData/CoreData.h>

typedef NS_ENUM(NSInteger, NCDBEufeItemSlot) {
	NCDBEufeItemSlotNone,
	NCDBEufeItemSlotHi,
	NCDBEufeItemSlotMed,
	NCDBEufeItemSlotLow,
	NCDBEufeItemSlotRig,
	NCDBEufeItemSlotSubsystem,
	NCDBEufeItemSlotStructure,
	NCDBEufeItemSlotMode,
	NCDBEufeItemSlotCharge,
	NCDBEufeItemSlotDrone,
	NCDBEufeItemSlotImplant,
	NCDBEufeItemSlotBooster,
	NCDBEufeItemSlotShip,
	NCDBEufeItemSlotControlTower
};


@class NCDBEveIcon;
@class NCDBInvType;
@class NCDBDgmAttributeType;
@class NCDBInvGroup;
@class NCDBMapSolarSystem;
@class NCDBEufeItemCategory;
@class NCDBChrRace;
@class NCDBStaStation;
@class NCDBMapDenormalize;
@class NCDBRamActivity;
@class NCDBMapRegion;
@interface NSManagedObjectContext (NCDatabase)

//NCDBEveIcon
- (NCDBEveIcon*) defaultTypeIcon;
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

//NCDBEufeItemCategory
- (NCDBEufeItemCategory*) shipsCategory;
- (NCDBEufeItemCategory*) controlTowersCategory;
- (NCDBEufeItemCategory*) categoryWithSlot:(NCDBEufeItemSlot) slot size:(int32_t) size race:(NCDBChrRace*) race;

//NCDBStaStation
- (NCDBStaStation*) staStationWithStationID:(int32_t) stationID;

//NCDBMapDenormalize
- (NCDBMapDenormalize*) mapDenormalizeWithItemID:(int32_t) itemID;

//NCDBRamActivity
- (NCDBRamActivity*) ramActivityWithActivityID:(int32_t) activityID;

//NCDBMapRegion
- (NCDBMapRegion*) mapRegionWithRegionID:(int32_t) regionID;


@end
