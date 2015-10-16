//
//  NCPOSFit.m
//  Neocom
//
//  Created by Артем Шиманский on 11.02.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCPOSFit.h"
#import "NCStorage.h"
#import <EVEAPI/EVEAPI.h>
#import "EVEAssetListItem+Neocom.h"
#import "NCDatabase.h"

@implementation NCLoadoutDataPOS

- (id) initWithCoder:(NSCoder *)aDecoder {
	if (self = [super init]) {
		self.structures = [aDecoder decodeObjectForKey:@"structures"];
	}
	return self;
}

- (void) encodeWithCoder:(NSCoder *)aCoder {
	if (self.structures)
		[aCoder encodeObject:self.structures forKey:@"structures"];
}

- (BOOL) isEqual:(id)object {
	if (![object isKindOfClass:[self class]])
		return NO;
	
	NSArray* a = self.structures;
	NSArray* b = [object structures];
	
	if (a != b && ![a isEqualToArray:b])
		return NO;
	else
		return YES;
}

@end

@implementation NCLoadoutDataPOSStructure

- (id) initWithCoder:(NSCoder *)aDecoder {
	if (self = [super init]) {
		self.typeID = [aDecoder decodeInt32ForKey:@"typeID"];
		self.chargeID = [aDecoder decodeInt32ForKey:@"chargeID"];
		self.state = static_cast<eufe::Module::State>([aDecoder decodeInt32ForKey:@"state"]);
		self.count = [aDecoder decodeInt32ForKey:@"count"];
	}
	return self;
}

- (void) encodeWithCoder:(NSCoder *)aCoder {
	[aCoder encodeInt32:self.typeID forKey:@"typeID"];
	[aCoder encodeInt32:self.chargeID forKey:@"chargeID"];
	[aCoder encodeInt32:self.state forKey:@"state"];
	[aCoder encodeInt32:self.count forKey:@"count"];
}

- (BOOL) isEqual:(NCLoadoutDataPOSStructure*)object {
	return [object isKindOfClass:[self class]] && self.typeID == object.typeID && self.chargeID == object.chargeID && self.state == object.state && self.count == object.count;
}

@end

@interface NCPOSFit()
@property (nonatomic, strong, readwrite) NCFittingEngine* engine;
@property (nonatomic, assign, readwrite) int32_t typeID;
@property (nonatomic, strong, readwrite) NSManagedObjectID* loadoutID;
@property (nonatomic, strong, readwrite) EVEAssetListItem* asset;

@property (nonatomic, strong) NCLoadoutDataPOS* loadoutData;
@property (nonatomic, strong) NSManagedObjectContext* storageManagedObjectContext;
@property (nonatomic, strong) NSManagedObjectContext* databaseManagedObjectContext;

@end

@implementation NCPOSFit

- (id) initWithLoadout:(NCLoadout*) loadout {
	if (self = [super init]) {
		[loadout.managedObjectContext performBlockAndWait:^{
			self.loadoutID = [loadout objectID];
			self.loadoutName = loadout.name;
			self.loadoutData = loadout.data.data;
			self.typeID = loadout.typeID;
		}];
	}
	return self;
}

- (id) initWithType:(NCDBInvType*) type {
	if (self = [super init]) {
		[type.managedObjectContext performBlockAndWait:^{
			self.typeID = type.typeID;
			self.loadoutName = type.typeName;
		}];
	}
	return self;
}

- (id) initWithAsset:(EVEAssetListItem*) asset {
	if (self = [super init]) {
		self.asset = asset;
		self.typeID = asset.typeID;
		self.loadoutName = asset.location.itemName ?: asset.typeName;

		/*
		self.type = [NCDBInvType invTypeWithTypeID:asset.typeID];
		if (!self.type)
			return nil;
		self.loadoutName = asset.location ? asset.location.itemName : self.type.typeName;
		self.loadoutData = [NCLoadoutDataPOS new];
		
		NSMutableDictionary* structuresDic = [NSMutableDictionary new];
		
		for (EVEAssetListItem* item in asset.contents) {
			NCDBInvType* type = item.type;
			if (type.group.category.categoryID == eufe::STRUCTURE_CATEGORY_ID && type.group.groupID != eufe::CONTROL_TOWER_GROUP_ID) {
				NCLoadoutDataPOSStructure* structure = structuresDic[@(item.typeID)];
				if (!structure) {
					structure = [NCLoadoutDataPOSStructure new];
					structure.typeID = item.typeID;
					structuresDic[@(item.typeID)] = structure;
				}
				structure.count += item.quantity;
			}

		}
		
		self.loadoutData.structures = [structuresDic allValues];*/
	}
	return self;
}

- (void) save {
	if (!self.engine)
		return;
	
	__block int32_t typeID = self.typeID;
	
	[self.engine performBlockAndWait:^{
		auto controlTower = self.engine.engine->getControlTower();
		if (!controlTower)
			return;

		typeID = controlTower->getTypeID();
		
		NSMutableDictionary* structuresDic = [NSMutableDictionary new];
		for (auto i: controlTower->getStructures()) {
			auto charge = i->getCharge();
			eufe::TypeID chargeID = charge ? charge->getTypeID() : 0;
			NSString* key = [NSString stringWithFormat:@"%d:%d:%d", i->getTypeID(), i->getState(), chargeID];
			NSDictionary* record = structuresDic[key];
			if (!record) {
				NCLoadoutDataPOSStructure* structure = [NCLoadoutDataPOSStructure new];
				structure.typeID = i->getTypeID();
				structure.state = i->getState();
				structure.chargeID = chargeID;
				structure.count = 1;
				record = @{@"structure": structure, @"order": @(structuresDic.count)};
				structuresDic[key]= record;
			}
			else {
				NCLoadoutDataPOSStructure* structure = record[@"structure"];
				structure.count++;
			}
			
		}
		
		NSArray* structures = [[[structuresDic allValues] sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"order" ascending:YES]]] valueForKey:@"structure"];

		self.loadoutData = [NCLoadoutDataPOS new];
		self.loadoutData.structures = structures;

		NSManagedObjectContext* context = self.storageManagedObjectContext;
		[context performBlock:^{
			NCLoadout* loadout;
			if (!self.loadoutID) {
				loadout = [[NCLoadout alloc] initWithEntity:[NSEntityDescription entityForName:@"Loadout" inManagedObjectContext:context] insertIntoManagedObjectContext:context];
				loadout.data = [[NCLoadoutData alloc] initWithEntity:[NSEntityDescription entityForName:@"LoadoutData" inManagedObjectContext:context] insertIntoManagedObjectContext:context];
			}
			else
				loadout = [self.storageManagedObjectContext objectWithID:self.loadoutID];
			
			if (![loadout.data.data isEqual:self.loadoutData])
				loadout.data.data = self.loadoutData;
			if (loadout.typeID != typeID)
				loadout.typeID = typeID;
			if (![self.loadoutName isEqualToString:loadout.name])
				loadout.name = self.loadoutName;
			if ([context hasChanges]) {
				[context save:nil];
				self.loadoutID = loadout.objectID;
			}
		}];
	}];
}

/*- (void) load {
	if (!self.engine)
		return;
	eufe::ControlTower* controlTower = self.engine->setControlTower(self.type.typeID);
	if (controlTower) {
		for (NCLoadoutDataPOSStructure* item in self.loadoutData.structures) {
			for (int n = item.count; n > 0; n--) {
				eufe::Structure* structure = controlTower->addStructure(item.typeID);
				if (!structure)
					break;
				structure->setState(item.state);
				if (item.chargeID)
					structure->setCharge(item.chargeID);
			}
		}
	}
}*/

#pragma mark - Private


- (NSManagedObjectContext*) storageManagedObjectContext {
	if (!_storageManagedObjectContext) {
		_storageManagedObjectContext = [[NCStorage sharedStorage] createManagedObjectContext];
	}
	return _storageManagedObjectContext;
}

- (NSManagedObjectContext*) databaseManagedObjectContext {
	if (!_databaseManagedObjectContext) {
		_databaseManagedObjectContext = [[NCDatabase sharedDatabase] createManagedObjectContext];
	}
	return _databaseManagedObjectContext;
}
@end
