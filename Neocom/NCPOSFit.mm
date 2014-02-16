//
//  NCPOSFit.m
//  Neocom
//
//  Created by Артем Шиманский on 11.02.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCPOSFit.h"
#import "NCStorage.h"
#import "EVEDBAPI.h"
#import "EVEOnlineAPI.h"
#import "EVEAssetListItem+Neocom.h"

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

- (BOOL) isEqual:(id)object {
	return [object isKindOfClass:[self class]] && self.typeID == [object typeID] && self.chargeID == [object chargeID] && self.state == [object state] && self.count == [object count];
}

@end

@interface NCPOSFit()
@property (nonatomic, strong) NCLoadoutDataPOS* loadoutData;

@end

@implementation NCPOSFit

- (id) initWithLoadout:(NCLoadout*) loadout {
	if (self = [super init]) {
		NCStorage* storage = [NCStorage sharedStorage];
		[storage.managedObjectContext performBlockAndWait:^{
			self.loadout = loadout;
			self.loadoutName = loadout.name;
			self.loadoutData = loadout.data.data;
			self.type = self.loadout.type;
		}];
	}
	return self;
}

- (id) initWithType:(EVEDBInvType*) type {
	if (self = [super init]) {
		self.loadoutName = type.typeName;
		self.type = type;
	}
	return self;
}

- (id) initWithAsset:(EVEAssetListItem*) asset {
	if (self = [super init]) {
		self.type = [EVEDBInvType invTypeWithTypeID:asset.typeID error:nil];
		if (!self.type)
			return nil;
		self.loadoutName = asset.location ? asset.location.itemName : self.type.typeName;
		self.loadoutData = [NCLoadoutDataPOS new];
		
		NSMutableDictionary* structuresDic = [NSMutableDictionary new];
		
		for (EVEAssetListItem* item in asset.contents) {
			EVEDBInvType* type = item.type;
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
		
		self.loadoutData.structures = [structuresDic allValues];
	}
	return self;
}

- (void) save {
	if (!self.engine)
		return;
	eufe::ControlTower* controlTower = self.engine->getControlTower();
	if (!controlTower)
		return;
	
	NCStorage* storage = [NCStorage sharedStorage];
	if (!self.loadout) {
		[storage.managedObjectContext performBlockAndWait:^{
			self.loadout = [[NCLoadout alloc] initWithEntity:[NSEntityDescription entityForName:@"Loadout" inManagedObjectContext:storage.managedObjectContext] insertIntoManagedObjectContext:storage.managedObjectContext];
			self.loadout.data = [[NCLoadoutData alloc] initWithEntity:[NSEntityDescription entityForName:@"LoadoutData" inManagedObjectContext:storage.managedObjectContext] insertIntoManagedObjectContext:storage.managedObjectContext];
		}];
	}
	self.loadoutData = [NCLoadoutDataPOS new];
	
	EVEDBInvType* type = nil;
	
	type = [EVEDBInvType invTypeWithTypeID:controlTower->getTypeID() error:nil];
	
	NSMutableDictionary* structuresDic = [NSMutableDictionary new];
	for (auto i: controlTower->getStructures()) {
		eufe::Charge* charge = i->getCharge();
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

	NSMutableArray* structures = [NSMutableArray new];
	for (NSDictionary* record in [[structuresDic allValues] sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"order" ascending:YES]]])
		[structures addObject:record[@"structure"]];

	
	self.loadoutData.structures = structures;
	
	[storage.managedObjectContext performBlockAndWait:^{
		if (![self.loadout.data.data isEqual:self.loadoutData])
			self.loadout.data.data = self.loadoutData;
		if (self.loadout.typeID != type.typeID)
			self.loadout.typeID = type.typeID;
		if (![self.loadoutName isEqualToString:self.loadout.name])
			self.loadout.name = self.loadoutName;
	}];
}

- (void) load {
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
}

@end
