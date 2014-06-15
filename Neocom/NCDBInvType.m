//
//  NCDBInvType.m
//  Neocom
//
//  Created by Shimanski Artem on 15.06.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
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
#import "NCDBInvMetaGroup.h"
#import "NCDBInvType.h"
#import "NCDBInvTypeMaterial.h"
#import "NCDBInvTypeRequiredSkill.h"
#import "NCDBMapDenormalize.h"
#import "NCDBRamInstallationTypeContent.h"
#import "NCDBRamTypeRequirement.h"
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
@dynamic blueprint;
@dynamic blueprintType;
@dynamic controlTower;
@dynamic controlTowerResources;
@dynamic denormalize;
@dynamic effects;
@dynamic group;
@dynamic icon;
@dynamic installationTypeContents;
@dynamic marketGroup;
@dynamic masteries;
@dynamic masterySkills;
@dynamic metaGroup;
@dynamic parentType;
@dynamic race;
@dynamic reguiredForSkill;
@dynamic requiredFor;
@dynamic requiredSkills;
@dynamic stations;
@dynamic typeDescription;
@dynamic typeMaterials;
@dynamic typeRequirements;
@dynamic variations;

@end
