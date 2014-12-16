//
//  NCDBEufeItemCategory+Neocom.h
//  Neocom
//
//  Created by Артем Шиманский on 18.06.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCDBEufeItemCategory.h"

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

@class NCDBChrRace;
@interface NCDBEufeItemCategory (Neocom)

+ (id) shipsCategory;
+ (id) controlTowersCategory;
+ (id) categoryWithSlot:(NCDBEufeItemSlot) slot size:(int32_t) size race:(NCDBChrRace*) race;

@end
