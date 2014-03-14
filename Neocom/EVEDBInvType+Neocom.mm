//
//  EVEDBInvType+Neocom.m
//  Neocom
//
//  Created by Артем Шиманский on 14.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "EVEDBInvType+Neocom.h"

@implementation EVEDBInvType (Neocom)

- (eufe::Module::Slot) slot {
	NSDictionary* effects = self.effectsDictionary;
	
	if (effects[@(eufe::LO_POWER_EFFECT_ID)])
		return eufe::Module::SLOT_LOW;
	else if (effects[@(eufe::MED_POWER_EFFECT_ID)])
		return eufe::Module::SLOT_MED;
	else if (effects[@(eufe::HI_POWER_EFFECT_ID)])
		return eufe::Module::SLOT_HI;
	else if (effects[@(eufe::RIG_SLOT_EFFECT_ID)])
		return eufe::Module::SLOT_RIG;
	else if (effects[@(eufe::SUBSYSTEM_EFFECT_ID)])
		return eufe::Module::SLOT_SUBSYSTEM;
	else
		return eufe::Module::SLOT_NONE;
}

- (NCTypeCategory) category {
	switch (self.group.categoryID) {
		case NCModuleCategoryID:
		case NCSubsystemCategoryID:
			return NCTypeCategoryModule;
		case NCChargeCategoryID:
			return NCTypeCategoryCharge;
		case NCDroneCategoryID:
			return NCTypeCategoryDrone;
		default:
			return NCTypeCategoryUnknown;
	}
}


@end
