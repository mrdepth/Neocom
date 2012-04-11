//
//  POSFit.m
//  EVEUniverse
//
//  Created by Mr. Depth on 3/16/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "POSFit.h"
#import "ItemInfo.h"
#import "Globals.h"
#import "EVEDBAPI.h"
#import "EVEOnlineAPI.h"
#import "EVEAssetListItem+AssetsViewController.h"
#import "NSString+UUID.h"

#include <functional>

@implementation POSFit
@synthesize fitID;
@synthesize fitName;

+ (id) posFitWithFitID:(NSString*) fitID fitName:(NSString*) fitName controlTower:(boost::shared_ptr<eufe::ControlTower>) aControlTower {
	return [[[POSFit alloc] initWithFitID:fitID fitName:fitName controlTower:aControlTower] autorelease];
}

+ (id) posFitWithDictionary:(NSDictionary*) dictionary engine:(eufe::Engine*) engine {
	return [[[POSFit alloc] initWithDictionary:dictionary engine:engine] autorelease];
}

+ (id) posFitWithAsset:(EVEAssetListItem*) asset engine:(eufe::Engine*) engine {
	return [[[POSFit alloc] initWithAsset:asset engine:engine] autorelease];
	
}

- (id) initWithFitID:(NSString*) aFitID fitName:(NSString*) aFitName controlTower:(boost::shared_ptr<eufe::ControlTower>) aControlTower {
	if (self = [super initWithItem:aControlTower error:nil]) {
		self.fitID = aFitID;
		self.fitName = aFitName;
	}
	return self;
}

- (id) initWithDictionary:(NSDictionary*) dictionary engine:(eufe::Engine*) engine {
	NSString* aFitID = [dictionary valueForKey:@"fitID"];
	NSString *aFitName = [dictionary valueForKey:@"fitName"];
	NSDictionary* fit = [dictionary valueForKey:@"fit"];
	NSInteger controlTowerID = [[fit valueForKey:@"controlTowerID"] integerValue];
	boost::shared_ptr<eufe::ControlTower> ct = engine->setControlTower(controlTowerID);

	if (self = [self initWithFitID:aFitID fitName:aFitName controlTower:ct]) {
		if (ct == NULL) {
			[self release];
			return nil;
		}
		for (NSDictionary* record in [fit valueForKey:@"structures"]) {
			NSInteger aTypeID = [[record valueForKey:@"typeID"] integerValue];
			NSInteger chargeID = [[record valueForKey:@"chargeID"] integerValue];
			if (aTypeID != 0) {
				eufe::Module::State state = static_cast<eufe::Module::State>([[record valueForKey:@"state"] integerValue]);
				boost::shared_ptr<eufe::Structure> structure = ct->addStructure(aTypeID);
				if (structure != NULL) {
					if (chargeID != 0)
						structure->setCharge(chargeID);
					if (structure->canHaveState(state))
						structure->setState(state);
				}
			}
		}
	}
	return self;
}

- (id) initWithAsset:(EVEAssetListItem*) asset engine:(eufe::Engine*) engine {
	boost::shared_ptr<eufe::ControlTower> ct = engine->setControlTower(asset.typeID);
	if (self = [self initWithItem:ct error:nil]) {
		self.fitName = asset.location.itemName ? asset.location.itemName : asset.type.typeName;
		if (ct == NULL) {
			[self release];
			return nil;
		}
		else {
			for (EVEAssetListItem* assetItem in asset.contents) {
				int amount = assetItem.quantity;
				if (amount < 1)
					amount = 1;
				EVEDBInvType* type = assetItem.type;
				if (type.group.category.categoryID == eufe::STRUCTURE_CATEGORY_ID && type.group.groupID != eufe::CONTROL_TOWER_GROUP_ID) {
					ct->addStructure(type.typeID);
				}
			}
		}
	}
	return self;
}


- (void) dealloc {
	[fitName release];
	[fitID release];
	[super dealloc];
}


- (boost::shared_ptr<eufe::ControlTower>) controlTower {
	return boost::dynamic_pointer_cast<eufe::ControlTower>(self.item);
}

- (NSDictionary*) dictionary {
	boost::shared_ptr<eufe::ControlTower> ct = self.controlTower;
	if (ct == NULL)
		return nil;
	ItemInfo* itemInfo = [ItemInfo itemInfoWithItem:ct error:NULL];
	
	NSMutableArray* structures = [NSMutableArray array];
	{
		eufe::StructuresList structuresList = ct->getStructures();
		eufe::StructuresList::const_iterator i, end = structuresList.end();
		for(i = structuresList.begin(); i != end; i++) {
			NSMutableDictionary* row = [NSMutableDictionary dictionaryWithObjectsAndKeys:
										[NSNumber numberWithInteger:(*i)->getTypeID()], @"typeID",
										[NSNumber numberWithInteger:(*i)->getState()], @"state", nil];
			if ((*i)->getCharge() != NULL)
				[row setValue:[NSNumber numberWithInteger:(*i)->getCharge()->getTypeID()] forKey:@"chargeID"];
			[structures addObject:row];
		}
	}
	
	NSDictionary* fit = [NSDictionary dictionaryWithObjectsAndKeys:
						 [NSNumber numberWithInteger:ct->getTypeID()], @"controlTowerID",
						 structures, @"structures", nil];
	
	if (!fitID)
		self.fitID = [NSString uuidString];

	return [NSDictionary dictionaryWithObjectsAndKeys:
			fitID, @"fitID",
			fitName, @"fitName",
			itemInfo.typeName, @"shipName",
			[itemInfo typeSmallImageName], @"imageName",
			[NSNumber numberWithBool:YES], @"isPOS",
			fit, @"fit",nil];
}

- (void) save {
	NSURL *url = [NSURL fileURLWithPath:[Globals fitsFilePath]];
	NSMutableArray *fits = [NSMutableArray arrayWithContentsOfURL:url];
	if (!fits)
		fits = [NSMutableArray array];
	if (!fitID) {
		self.fitID = [NSString uuidString];
	}
	NSDictionary *record = [self dictionary];
	
	BOOL bFind = NO;
	NSInteger i = 0;
	for (NSDictionary *aItem in fits) {
		if ([[aItem valueForKey:@"fitID"] isEqualToString:fitID]) {
			[fits replaceObjectAtIndex:i withObject:record];
			bFind = YES;
			break;
		}
		i++;
	}
	if (!bFind)
		[fits addObject:record];
	[fits writeToURL:url atomically:YES];
}

@end
