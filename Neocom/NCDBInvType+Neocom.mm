//
//  NCDBInvType+Neocom.m
//  Neocom
//
//  Created by Артем Шиманский on 11.06.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCDBInvType+Neocom.h"
#import "NCDBInvMetaGroup.h"
#import "NCDatabase.h"
#import <objc/runtime.h>
#import <dgmpp/dgmpp.h>

@implementation NCDBInvType (Neocom)

- (NSString*) metaGroupName {
	return self.metaGroup.metaGroupName;
}

- (NSDictionary*) attributesDictionary {
	NSDictionary* attributesDictionary = objc_getAssociatedObject(self, (void*) @"attributesDictionary");
	if (!attributesDictionary) {
		NSMutableDictionary* dic = [NSMutableDictionary new];
		for (NCDBDgmTypeAttribute* attribute in self.attributes)
			dic[@(attribute.attributeType.attributeID)] = attribute;
		attributesDictionary = dic;
		objc_setAssociatedObject(self, (void*) @"attributesDictionary", attributesDictionary, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	}
	return attributesDictionary;
}

- (NSDictionary*) effectsDictionary {
	NSDictionary* effectsDictionary = objc_getAssociatedObject(self, (void*) @"effectsDictionary");
	if (!effectsDictionary) {
		NSMutableDictionary* dic = [NSMutableDictionary new];
		for (NCDBDgmEffect* effect in self.effects)
			dic[@(effect.effectID)] = effect;
		effectsDictionary = dic;
		objc_setAssociatedObject(self, (void*) @"effectsDictionary", effectsDictionary, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	}
	return effectsDictionary;
}

- (int32_t) slot {
	NSDictionary* effects = self.effectsDictionary;
	
	if (effects[@(dgmpp::LO_POWER_EFFECT_ID)])
		return dgmpp::Module::SLOT_LOW;
	else if (effects[@(dgmpp::MED_POWER_EFFECT_ID)])
		return dgmpp::Module::SLOT_MED;
	else if (effects[@(dgmpp::HI_POWER_EFFECT_ID)])
		return dgmpp::Module::SLOT_HI;
	else if (effects[@(dgmpp::RIG_SLOT_EFFECT_ID)])
		return dgmpp::Module::SLOT_RIG;
	else if (effects[@(dgmpp::SUBSYSTEM_EFFECT_ID)])
		return dgmpp::Module::SLOT_SUBSYSTEM;
	else
		return dgmpp::Module::SLOT_NONE;
}

- (NCTypeCategory) category {
	switch (self.group.category.categoryID) {
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
