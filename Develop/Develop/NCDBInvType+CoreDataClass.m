//
//  NCDBInvType+CoreDataClass.m
//  Develop
//
//  Created by Artem Shimanski on 20.10.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCDBInvType+CoreDataClass.h"
#import "NCDBCertCertificate+CoreDataClass.h"
#import "NCDBCertSkill+CoreDataClass.h"
#import "NCDBChrRace+CoreDataClass.h"
#import "NCDBDgmEffect+CoreDataClass.h"
#import "NCDBDgmTypeAttribute+CoreDataClass.h"
#import "NCDBDgmppHullType+CoreDataClass.h"
#import "NCDBDgmppItem+CoreDataClass.h"
#import "NCDBEveIcon+CoreDataClass.h"
#import "NCDBIndBlueprintType+CoreDataClass.h"
#import "NCDBIndProduct+CoreDataClass.h"
#import "NCDBIndRequiredMaterial+CoreDataClass.h"
#import "NCDBIndRequiredSkill+CoreDataClass.h"
#import "NCDBInvControlTower+CoreDataClass.h"
#import "NCDBInvControlTowerResource+CoreDataClass.h"
#import "NCDBInvGroup+CoreDataClass.h"
#import "NCDBInvMarketGroup+CoreDataClass.h"
#import "NCDBInvMetaGroup+CoreDataClass.h"
#import "NCDBInvTypeRequiredSkill+CoreDataClass.h"
#import "NCDBMapDenormalize+CoreDataClass.h"
#import "NCDBRamInstallationTypeContent+CoreDataClass.h"
#import "NCDBStaStation+CoreDataClass.h"
#import "NCDBTxtDescription+CoreDataClass.h"
#import "NCDBWhType+CoreDataClass.h"

@implementation NCDBInvType

+ (NSFetchRequest<NCDBInvType *> *)fetchRequestWithTypeID:(int32_t) typeID {
	NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"InvType"];
	request.predicate = [NSPredicate predicateWithFormat:@"typeID == %d", typeID];
	request.fetchLimit = 1;
	return request;
}

- (NCFetchedCollection<NCDBDgmTypeAttribute*>*) attributes {
	return [[NCFetchedCollection alloc] initWithEntity:@"DgmTypeAttribute" predicateFormat:@"type == %@ AND attributeType.attributeID==%@" argumentArray:@[self] managedObjectContext:self.managedObjectContext];
}

@end
