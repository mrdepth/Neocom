//
//  NCDBInvType.m
//  Neocom
//
//  Created by Артем Шиманский on 18.09.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
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
@dynamic blueprintType;
@dynamic certificates;
@dynamic controlTower;
@dynamic controlTowerResources;
@dynamic denormalize;
@dynamic effects;
@dynamic eufeItem;
@dynamic group;
@dynamic icon;
@dynamic indRequiredSkills;
@dynamic installationTypeContents;
@dynamic marketGroup;
@dynamic masterySkills;
@dynamic materials;
@dynamic metaGroup;
@dynamic parentType;
@dynamic products;
@dynamic race;
@dynamic reguiredForSkill;
@dynamic requiredSkills;
@dynamic stations;
@dynamic typeDescription;
@dynamic variations;

@end
