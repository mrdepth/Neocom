//
//  NCDBInvType.m
//  NCDatabase
//
//  Created by Артем Шиманский on 15.05.14.
//
//

#import "NCDBInvType.h"
#import "NCDBCertMastery.h"
#import "NCDBCertSkill.h"
#import "NCDBChrRace.h"
#import "NCDBDgmEffect.h"
#import "NCDBDgmTypeAttribute.h"
#import "NCDBEveIcon.h"
#import "NCDBInvBlueprintType.h"
#import "NCDBInvControlTower.h"
#import "NCDBInvControlTowerResource.h"
#import "NCDBInvGroup.h"
#import "NCDBInvMarketGroup.h"
#import "NCDBInvMetaType.h"
#import "NCDBInvTypeMaterial.h"
#import "NCDBMapDenormalize.h"
#import "NCDBRamInstallationTypeContent.h"
#import "NCDBRamTypeRequirement.h"
#import "NCDBStaStation.h"


@implementation NCDBInvType

@dynamic basePrice;
@dynamic capacity;
@dynamic mass;
@dynamic portionSize;
@dynamic published;
@dynamic radius;
@dynamic typeID;
@dynamic typeName;
@dynamic volume;
@dynamic attributes;
@dynamic blueprint;
@dynamic blueprintType;
@dynamic controlTower;
@dynamic controlTowerResources;
@dynamic denormalize;
@dynamic effects;
@dynamic group;
@dynamic icon;
@dynamic marketGroup;
@dynamic metaType;
@dynamic race;
@dynamic typeMaterials;
@dynamic variations;
@dynamic masterySkills;
@dynamic masteries;
@dynamic installationTypeContents;
@dynamic typeRequirements;
@dynamic requiredFor;
@dynamic stations;

@end
