//
//  NCDBInvType+CoreDataClass.h
//  Develop
//
//  Created by Artem Shimanski on 20.10.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "NCFetchedCollection.h"

@class NCDBCertCertificate, NCDBCertSkill, NCDBChrRace, NCDBDgmEffect, NCDBDgmTypeAttribute, NCDBDgmppHullType, NCDBDgmppItem, NCDBEveIcon, NCDBIndBlueprintType, NCDBIndProduct, NCDBIndRequiredMaterial, NCDBIndRequiredSkill, NCDBInvControlTower, NCDBInvControlTowerResource, NCDBInvGroup, NCDBInvMarketGroup, NCDBInvMetaGroup, NCDBInvTypeRequiredSkill, NCDBMapDenormalize, NCDBRamInstallationTypeContent, NCDBStaStation, NCDBTxtDescription, NCDBWhType;

NS_ASSUME_NONNULL_BEGIN

@interface NCDBInvType : NSManagedObject
+ (NSFetchRequest<NCDBInvType *> *)fetchRequestWithTypeID:(int32_t) typeID;
- (NCFetchedCollection<NCDBDgmTypeAttribute*>*) attributes;

@end

NS_ASSUME_NONNULL_END

#import "NCDBInvType+CoreDataProperties.h"
