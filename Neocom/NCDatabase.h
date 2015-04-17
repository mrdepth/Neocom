//
//  NCDatabase.h
//  Neocom
//
//  Created by Артем Шиманский on 09.06.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "NCDBCertCertificate.h"
#import "NCDBCertMastery.h"
#import "NCDBCertMasteryLevel.h"
#import "NCDBCertSkill.h"
#import "NCDBChrRace.h"
#import "NCDBEveIcon.h"
#import "NCDBEveIconImage.h"
#import "NCDBInvControlTower.h"
#import "NCDBInvMarketGroup.h"
#import "NCDBInvControlTowerResource.h"
#import "NCDBRamAssemblyLineType.h"
#import "NCDBMapSolarSystem.h"
#import "NCDBMapDenormalize.h"
#import "NCDBInvType.h"
#import "NCDBStaStation.h"
#import "NCDBRamActivity.h"
#import "NCDBDgmAttributeType.h"
#import "NCDBDgmEffect.h"
#import "NCDBInvCategory.h"
#import "NCDBInvGroup.h"
#import "NCDBDgmAttributeCategory.h"
#import "NCDBNpcGroup.h"
#import "NCDBMapRegion.h"
#import "NCDBMapConstellation.h"
#import "NCDBInvControlTowerResourcePurpose.h"
#import "NCDBInvMetaGroup.h"
#import "NCDBTxtDescription.h"
#import "NCDBDgmTypeAttribute.h"
#import "NCDBRamInstallationTypeContent.h"
#import "NCDBEveUnit.h"
#import "NCDBInvTypeRequiredSkill.h"
#import "NCDBEufeItemCategory.h"
#import "NCDBEufeItemGroup.h"
#import "NCDBEufeItem.h"
#import "NCDBIndActivity.h"
#import "NCDBIndBlueprintType.h"
#import "NCDBIndProduct.h"
#import "NCDBIndRequiredMaterial.h"
#import "NCDBIndRequiredSkill.h"
#import "NCDBWhType.h"

#import "NCDBEveIcon+Neocom.h"
#import "NCDBInvType+Neocom.h"
#import "NCDBDgmAttributeType+Neocom.h"
#import "NCDBInvGroup+Neocom.h"
#import "NCDBMapSolarSystem+Neocom.h"
#import "NCDBEufeItemCategory+Neocom.h"
#import "NCDBStaStation+Neocom.h"
#import "NCDBMapDenormalize+Neocom.h"
#import "NCDBRamActivity+Neocom.h"
#import "NCDBMapRegion+Neocom.h"

@interface NCDatabase : NSObject
@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (readonly, strong, nonatomic) NSManagedObjectContext *backgroundManagedObjectContext;

+ (id) sharedDatabase;

@end
