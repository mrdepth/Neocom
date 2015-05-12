//
//  NCDBInvType.m
//  NCDatabase
//
//  Created by Артем Шиманский on 17.09.14.
//
//

#import "NCDBInvType.h"
#import "NCDBCertCertificate.h"
#import "NCDBCertSkill.h"
#import "NCDBChrRace.h"
#import "NCDBDgmEffect.h"
#import "NCDBDgmTypeAttribute.h"
#import "NCDBEufeItem.h"
#import "NCDBEveIcon.h"
#import "NCDBIndBlueprintType.h"
#import "NCDBIndProduct.h"
#import "NCDBIndRequiredMaterial.h"
#import "NCDBIndRequiredSkill.h"
#import "NCDBInvControlTower.h"
#import "NCDBInvControlTowerResource.h"
#import "NCDBInvGroup.h"
#import "NCDBInvMarketGroup.h"
#import "NCDBInvMetaGroup.h"
#import "NCDBInvType.h"
#import "NCDBInvTypeRequiredSkill.h"
#import "NCDBMapDenormalize.h"
#import "NCDBRamInstallationTypeContent.h"
#import "NCDBStaStation.h"
#import "NCDBTxtDescription.h"


@implementation NCDBInvType

@dynamic basePrice;
@dynamic capacity;
@dynamic mass;
@dynamic metaGroupName;
@dynamic metaLevel;
@dynamic portionSize;
@dynamic published;
@dynamic radius;
@dynamic typeID;
@dynamic typeName;
@dynamic volume;
@dynamic attributes;
@dynamic products;
@dynamic blueprintType;
@dynamic certificates;
@dynamic controlTower;
@dynamic controlTowerResources;
@dynamic denormalize;
@dynamic effects;
@dynamic eufeItem;
@dynamic group;
@dynamic icon;
@dynamic installationTypeContents;
@dynamic marketGroup;
@dynamic masterySkills;
@dynamic metaGroup;
@dynamic parentType;
@dynamic race;
@dynamic requiredForSkill;
@dynamic requiredSkills;
@dynamic stations;
@dynamic typeDescription;
@dynamic materials;
@dynamic indRequiredSkills;
@dynamic variations;
@dynamic wormhole;

@end
