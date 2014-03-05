//
//  NCShipFit.m
//  Neocom
//
//  Created by Артем Шиманский on 31.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCShipFit.h"
#import "EVEDBAPI.h"
#import "NCStorage.h"
#import "BattleClinicAPI.h"
#import "NeocomAPI.h"
#import "EVEOnlineAPI.h"
#import "EVEAssetListItem+Neocom.h"
#import "EVEDBInvType+Neocom.h"
#import "NCKillMail.h"

@implementation NCLoadoutDataShip

- (id) initWithCoder:(NSCoder *)aDecoder {
	if (self = [super init]) {
		self.hiSlots = [aDecoder decodeObjectForKey:@"hiSlots"];
		self.medSlots = [aDecoder decodeObjectForKey:@"medSlots"];
		self.lowSlots = [aDecoder decodeObjectForKey:@"lowSlots"];
		self.rigSlots = [aDecoder decodeObjectForKey:@"rigSlots"];
		self.subsystems = [aDecoder decodeObjectForKey:@"subsystems"];
		self.drones = [aDecoder decodeObjectForKey:@"drones"];
		self.cargo = [aDecoder decodeObjectForKey:@"cargo"];
		self.implants = [aDecoder decodeObjectForKey:@"implants"];
		self.boosters = [aDecoder decodeObjectForKey:@"boosters"];
	}
	return self;
}

- (void) encodeWithCoder:(NSCoder *)aCoder {
	if (self.hiSlots)
		[aCoder encodeObject:self.hiSlots forKey:@"hiSlots"];
	if (self.medSlots)
		[aCoder encodeObject:self.medSlots forKey:@"medSlots"];
	if (self.lowSlots)
		[aCoder encodeObject:self.lowSlots forKey:@"lowSlots"];
	if (self.rigSlots)
		[aCoder encodeObject:self.rigSlots forKey:@"rigSlots"];
	if (self.subsystems)
		[aCoder encodeObject:self.subsystems forKey:@"subsystems"];
	if (self.drones)
		[aCoder encodeObject:self.drones forKey:@"drones"];
	if (self.cargo)
		[aCoder encodeObject:self.cargo forKey:@"cargo"];
	if (self.implants)
		[aCoder encodeObject:self.implants forKey:@"implants"];
	if (self.boosters)
		[aCoder encodeObject:self.boosters forKey:@"boosters"];
	
	
}

- (BOOL) isEqual:(id)object {
	if (![object isKindOfClass:[self class]])
		return NO;
	for (NSString* key in @[@"hiSlots", @"medSlots", @"lowSlots", @"rigSlots", @"subsystems", @"drones", @"cargo", @"implants", @"boosters"]) {
		NSArray* a = [self valueForKey:key];
		NSArray* b = [object valueForKey:key];
		if (a != b && ![a isEqualToArray:b])
			return NO;
	}
	return YES;
}

@end

@implementation NCLoadoutDataShipModule

- (id) initWithCoder:(NSCoder *)aDecoder {
	if (self = [super init]) {
		self.typeID = [aDecoder decodeInt32ForKey:@"typeID"];
		self.chargeID = [aDecoder decodeInt32ForKey:@"chargeID"];
		self.state = static_cast<eufe::Module::State>([aDecoder decodeInt32ForKey:@"state"]);
	}
	return self;
}

- (void) encodeWithCoder:(NSCoder *)aCoder {
	[aCoder encodeInt32:self.typeID forKey:@"typeID"];
	[aCoder encodeInt32:self.chargeID forKey:@"chargeID"];
	[aCoder encodeInt32:self.state forKey:@"state"];
}

- (BOOL) isEqual:(id)object {
	return [object isKindOfClass:[self class]] && self.typeID == [object typeID] && self.chargeID == [object chargeID] && self.state == [object state];
}

@end

@implementation NCLoadoutDataShipDrone

- (id) initWithCoder:(NSCoder *)aDecoder {
	if (self = [super init]) {
		self.typeID = [aDecoder decodeInt32ForKey:@"typeID"];
		self.count = [aDecoder decodeInt32ForKey:@"count"];
		self.active = [aDecoder decodeBoolForKey:@"active"];
	}
	return self;
}

- (void) encodeWithCoder:(NSCoder *)aCoder {
	[aCoder encodeInt32:self.typeID forKey:@"typeID"];
	[aCoder encodeInt32:self.count forKey:@"count"];
	[aCoder encodeBool:self.active forKey:@"active"];
}

- (BOOL) isEqual:(id)object {
	return [object isKindOfClass:[self class]] && self.typeID == [object typeID] && self.count == [object count] && self.active == [object active];
}

@end

@implementation NCLoadoutDataShipImplant

- (id) initWithCoder:(NSCoder *)aDecoder {
	if (self = [super init]) {
		self.typeID = [aDecoder decodeInt32ForKey:@"typeID"];
	}
	return self;
}

- (void) encodeWithCoder:(NSCoder *)aCoder {
	[aCoder encodeInt32:self.typeID forKey:@"typeID"];
}

- (BOOL) isEqual:(id)object {
	return [object isKindOfClass:[self class]] && self.typeID == [object typeID];
}

@end

@implementation NCLoadoutDataShipBooster

- (id) initWithCoder:(NSCoder *)aDecoder {
	if (self = [super init]) {
		self.typeID = [aDecoder decodeInt32ForKey:@"typeID"];
	}
	return self;
}

- (void) encodeWithCoder:(NSCoder *)aCoder {
	[aCoder encodeInt32:self.typeID forKey:@"typeID"];
}

- (BOOL) isEqual:(id)object {
	return [object isKindOfClass:[self class]] && self.typeID == [object typeID];
}

@end

@implementation NCLoadoutDataShipCargoItem

- (id) initWithCoder:(NSCoder *)aDecoder {
	if (self = [super init]) {
		self.typeID = [aDecoder decodeInt32ForKey:@"typeID"];
		self.count = [aDecoder decodeInt32ForKey:@"count"];
	}
	return self;
}

- (void) encodeWithCoder:(NSCoder *)aCoder {
	[aCoder encodeInt32:self.typeID forKey:@"typeID"];
	[aCoder encodeInt32:self.count forKey:@"count"];
}

- (BOOL) isEqual:(id)object {
	return [object isKindOfClass:[self class]] && self.typeID == [object typeID] && self.count == [object count];
}

@end


@interface NCShipFit()
@property (nonatomic, strong) NCLoadoutDataShip* loadoutData;
- (void) setSkillLevels:(NSDictionary*) skillLevels;
@end

@implementation NCShipFit

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

- (id) initWithBattleClinicLoadout:(BCEveLoadout*) bcLoadout {
	if (self = [super init]) {
		NSMutableArray* components = [NSMutableArray arrayWithArray:[bcLoadout.fitting componentsSeparatedByString:@":"]];
		[components removeObjectAtIndex:0];
		NSInteger shipID = [components[0] integerValue];
		
		if (!shipID)
			return nil;
		else {
			[components removeObjectAtIndex:0];
			self.type = [EVEDBInvType invTypeWithTypeID:shipID error:nil];
			if (!self.type)
				return nil;
			self.loadoutName = bcLoadout.title;
			self.loadoutData = [NCLoadoutDataShip new];

			NSMutableArray* hiSlots = [NSMutableArray new];
			NSMutableArray* medSlots = [NSMutableArray new];
			NSMutableArray* lowSlots = [NSMutableArray new];
			NSMutableArray* rigSlots = [NSMutableArray new];
			NSMutableArray* subsystems = [NSMutableArray new];
			NSArray* drones = nil;
			NSArray* cargo = nil;
			NSMutableDictionary* dronesDic = [NSMutableDictionary new];
			NSMutableDictionary* cargoDic = [NSMutableDictionary new];

			for (NSString *component in components) {
				NSArray *fields = [component componentsSeparatedByString:@"*"];
				if (fields.count == 0)
					continue;
				NSInteger typeID = [[fields objectAtIndex:0] integerValue];
				NSInteger amount = fields.count > 1 ? [[fields objectAtIndex:1] integerValue] : 1;
				EVEDBInvType *type = [EVEDBInvType invTypeWithTypeID:typeID error:nil];
				if (type) {
					switch (type.category) {
						case NCTypeCategoryModule: {
							NSMutableArray* modules = nil;
							switch (type.slot) {
								case eufe::Module::SLOT_LOW:
									modules = lowSlots;
									break;
								case eufe::Module::SLOT_MED:
									modules = medSlots;
									break;
								case eufe::Module::SLOT_HI:
									modules = hiSlots;
									break;
								case eufe::Module::SLOT_RIG:
									modules = rigSlots;
									break;
								case eufe::Module::SLOT_SUBSYSTEM:
									modules = subsystems;
									break;
								default:
									break;
							}
							for (int i = 0; i < amount; i++) {
								NCLoadoutDataShipModule* module = [NCLoadoutDataShipModule new];
								module.typeID = typeID;
								module.state = eufe::Module::STATE_ACTIVE;
								[modules addObject:module];
							}
							break;
						}
						case NCTypeCategoryDrone: {
							NCLoadoutDataShipDrone* drone = dronesDic[@(typeID)];
							if (!drone) {
								drone = [NCLoadoutDataShipDrone new];
								drone.typeID = typeID;
								drone.active = true;
								dronesDic[@(typeID)] = drone;
							}
							drone.count += amount;
							break;
						}
						case NCTypeCategoryCharge: {
							NCLoadoutDataShipCargoItem* item = cargoDic[@(typeID)];
							if (!item) {
								item = [NCLoadoutDataShipCargoItem new];
								item.typeID = typeID;
								cargoDic[@(typeID)] = item;
							}
							item.count += amount;
							break;
						}
						default:
							break;
					}
				}
			}
			drones = [dronesDic allValues];
			cargo = [cargoDic allValues];
			
			self.loadoutData.hiSlots = hiSlots;
			self.loadoutData.medSlots = medSlots;
			self.loadoutData.lowSlots = lowSlots;
			self.loadoutData.rigSlots = rigSlots;
			self.loadoutData.subsystems = subsystems;
			self.loadoutData.drones = drones;
			self.loadoutData.cargo = cargo;
			self.loadoutData.implants = @[];
			self.loadoutData.boosters = @[];
		}
	}
	return self;
}

- (id) initWithAPILoadout:(NAPISearchItem*) apiLoadout {
	if (self = [super init]) {
		NSArray* components = [apiLoadout.canonicalName componentsSeparatedByString:@"|"];
		if (components.count > 0) {
			NSInteger shipID = [components[0] integerValue];
			
			self.type = [EVEDBInvType invTypeWithTypeID:shipID error:nil];
			if (!self.type)
				return nil;
			self.loadoutName = apiLoadout.typeName;
			self.loadoutData = [NCLoadoutDataShip new];

			
			NSMutableArray* hiSlots = [NSMutableArray new];
			NSMutableArray* medSlots = [NSMutableArray new];
			NSMutableArray* lowSlots = [NSMutableArray new];
			NSMutableArray* rigSlots = [NSMutableArray new];
			NSMutableArray* subsystems = [NSMutableArray new];
			NSMutableArray* implants = [NSMutableArray new];
			NSMutableArray* boosters = [NSMutableArray new];
			NSArray* drones = nil;
			NSMutableDictionary* dronesDic = [NSMutableDictionary new];
			
			
			if (components.count > 1) {
				for (NSString* component in [components[1] componentsSeparatedByString:@";"]) {
					NSArray* array = [component componentsSeparatedByString:@":"];
					eufe::TypeID typeID = array.count > 0 ? [array[0] integerValue] : 0;
					eufe::TypeID chargeID = array.count > 1 ? [array[1] integerValue] : 0;
					int count = array.count > 2 ? [array[2] integerValue] : 1;
					if (!typeID)
						continue;
					
					EVEDBInvType *type = [EVEDBInvType invTypeWithTypeID:typeID error:nil];
					
					NSMutableArray* modules = nil;
					switch (type.slot) {
						case eufe::Module::SLOT_LOW:
							modules = lowSlots;
							break;
						case eufe::Module::SLOT_MED:
							modules = medSlots;
							break;
						case eufe::Module::SLOT_HI:
							modules = hiSlots;
							break;
						case eufe::Module::SLOT_RIG:
							modules = rigSlots;
							break;
						case eufe::Module::SLOT_SUBSYSTEM:
							modules = subsystems;
							break;
						default:
							break;
					}
					for (int i = 0; i < count; i++) {
						NCLoadoutDataShipModule* module = [NCLoadoutDataShipModule new];
						module.typeID = typeID;
						module.state = eufe::Module::STATE_ACTIVE;
						module.chargeID = chargeID;
						[modules addObject:module];
					}
				}
			}
			
			if (components.count > 2) {
				for (NSString* component in [components[2] componentsSeparatedByString:@";"]) {
					NSArray* array = [component componentsSeparatedByString:@":"];
					eufe::TypeID typeID = array.count > 0 ? [array[0] integerValue] : 0;
					int count = array.count > 1 ? [array[1] integerValue] : 0;
					if (!typeID)
						continue;
					
					NCLoadoutDataShipDrone* drone = dronesDic[@(typeID)];
					if (!drone) {
						drone = [NCLoadoutDataShipDrone new];
						drone.typeID = typeID;
						drone.active = true;
						dronesDic[@(typeID)] = drone;
					}
					drone.count += count;
				}
			}
			
			if (components.count > 3) {
				for (NSString* component in [components[3] componentsSeparatedByString:@";"]) {
					eufe::TypeID typeID = [component integerValue];
					if (typeID) {
						NCLoadoutDataShipImplant* implant = [NCLoadoutDataShipImplant new];
						implant.typeID = typeID;
						[implants addObject:implant];
					}
				}
			}
			
			if (components.count > 4) {
				for (NSString* component in [components[4] componentsSeparatedByString:@";"]) {
					eufe::TypeID typeID = [component integerValue];
					if (typeID) {
						NCLoadoutDataShipBooster* booster = [NCLoadoutDataShipBooster new];
						booster.typeID = typeID;
						[boosters addObject:booster];
					}
				}
			}
			drones = [dronesDic allValues];
			
			self.loadoutData.hiSlots = hiSlots;
			self.loadoutData.medSlots = medSlots;
			self.loadoutData.lowSlots = lowSlots;
			self.loadoutData.rigSlots = rigSlots;
			self.loadoutData.subsystems = subsystems;
			self.loadoutData.drones = drones;
			self.loadoutData.cargo = @[];
			self.loadoutData.implants = implants;
			self.loadoutData.boosters = boosters;

		}
		else
			return nil;
	}
	return self;
}

- (id) initWithAsset:(EVEAssetListItem*) asset {
	if (self = [super init]) {
		self.type = [EVEDBInvType invTypeWithTypeID:asset.typeID error:nil];
		if (!self.type)
			return nil;
		self.loadoutName = asset.location ? asset.location.itemName : self.type.typeName;
		self.loadoutData = [NCLoadoutDataShip new];
		
		NSMutableArray* hiSlots = [NSMutableArray new];
		NSMutableArray* medSlots = [NSMutableArray new];
		NSMutableArray* lowSlots = [NSMutableArray new];
		NSMutableArray* rigSlots = [NSMutableArray new];
		NSMutableArray* subsystems = [NSMutableArray new];
		NSArray* drones = nil;
		NSArray* cargo = nil;
		NSMutableDictionary* dronesDic = [NSMutableDictionary new];
		NSMutableDictionary* cargoDic = [NSMutableDictionary new];
		
		for (EVEAssetListItem* item in asset.contents) {
			if (item.flag >= EVEInventoryFlagHiSlot0 && item.flag <= EVEInventoryFlagHiSlot7) {
				for (int i = 0; i < item.quantity; i++) {
					NCLoadoutDataShipModule* module = [NCLoadoutDataShipModule new];
					module.typeID = item.typeID;
					module.state = eufe::Module::STATE_ACTIVE;
					[hiSlots addObject:module];
				}
			}
			else if (item.flag >= EVEInventoryFlagMedSlot0 && item.flag <= EVEInventoryFlagMedSlot7) {
				for (int i = 0; i < item.quantity; i++) {
					NCLoadoutDataShipModule* module = [NCLoadoutDataShipModule new];
					module.typeID = item.typeID;
					module.state = eufe::Module::STATE_ACTIVE;
					[medSlots addObject:module];
				}
			}
			else if (item.flag >= EVEInventoryFlagLoSlot0 && item.flag <= EVEInventoryFlagLoSlot7) {
				for (int i = 0; i < item.quantity; i++) {
					NCLoadoutDataShipModule* module = [NCLoadoutDataShipModule new];
					module.typeID = item.typeID;
					module.state = eufe::Module::STATE_ACTIVE;
					[lowSlots addObject:module];
				}
			}
			else if (item.flag >= EVEInventoryFlagRigSlot0 && item.flag <= EVEInventoryFlagRigSlot7) {
				for (int i = 0; i < item.quantity; i++) {
					NCLoadoutDataShipModule* module = [NCLoadoutDataShipModule new];
					module.typeID = item.typeID;
					module.state = eufe::Module::STATE_ACTIVE;
					[rigSlots addObject:module];
				}
			}
			else if (item.flag >= EVEInventoryFlagSubSystem0 && item.flag <= EVEInventoryFlagSubSystem7) {
				for (int i = 0; i < item.quantity; i++) {
					NCLoadoutDataShipModule* module = [NCLoadoutDataShipModule new];
					module.typeID = item.typeID;
					module.state = eufe::Module::STATE_ACTIVE;
					[subsystems addObject:module];
				}
			}
			else if (item.flag == EVEInventoryFlagDroneBay) {
				NCLoadoutDataShipDrone* drone = dronesDic[@(item.typeID)];
				if (!drone) {
					drone = [NCLoadoutDataShipDrone new];
					drone.typeID = item.typeID;
					drone.active = true;
					dronesDic[@(item.typeID)] = drone;
				}
				drone.count += item.quantity;
			}
			else {
				NCLoadoutDataShipCargoItem* cargo = cargoDic[@(item.typeID)];
				if (!cargo) {
					cargo = [NCLoadoutDataShipCargoItem new];
					cargo.typeID = item.typeID;
					cargoDic[@(item.typeID)] = cargo;
				}
				cargo.count += item.quantity;
			}
		}
		
		drones = [dronesDic allValues];
		cargo = [cargoDic allValues];
		
		self.loadoutData.hiSlots = hiSlots;
		self.loadoutData.medSlots = medSlots;
		self.loadoutData.lowSlots = lowSlots;
		self.loadoutData.rigSlots = rigSlots;
		self.loadoutData.subsystems = subsystems;
		self.loadoutData.drones = drones;
		self.loadoutData.cargo = cargo;
		self.loadoutData.implants = @[];
		self.loadoutData.boosters = @[];
	}
	return self;
}

- (id) initWithKillMail:(NCKillMail*) killMail {
	if (self = [super init]) {
		self.type = killMail.victim.shipType;
		if (!self.type)
			return nil;
		self.loadoutName = [NSString stringWithFormat:@"%@ - %@", self.type.typeName , killMail.victim.characterName];
		self.loadoutData = [NCLoadoutDataShip new];
		
		NSMutableArray* hiSlots = [NSMutableArray new];
		NSMutableArray* medSlots = [NSMutableArray new];
		NSMutableArray* lowSlots = [NSMutableArray new];
		NSMutableArray* rigSlots = [NSMutableArray new];
		NSMutableArray* subsystems = [NSMutableArray new];
		NSArray* drones = nil;
		NSArray* cargo = nil;
		NSMutableDictionary* dronesDic = [NSMutableDictionary new];
		NSMutableDictionary* cargoDic = [NSMutableDictionary new];
		
		NSMutableArray* slots[] = {hiSlots, medSlots, lowSlots, rigSlots, subsystems};
		NSMutableDictionary* modules = [NSMutableDictionary new];
		NSMutableDictionary* charges = [NSMutableDictionary new];
		
		NSArray* items[] = {killMail.hiSlots, killMail.medSlots, killMail.lowSlots, killMail.rigSlots, killMail.subsystemSlots};
		for (int i = 0; i < 5; i++) {
			for (NCKillMailItem* item in items[i]) {
				if (item.type.category == NCTypeCategoryModule) {
					for (int j = 0; j < item.qty; j++) {
						NCLoadoutDataShipModule* module = [NCLoadoutDataShipModule new];
						module.typeID = item.type.typeID;
						module.state = eufe::Module::STATE_ACTIVE;
						[slots[i] addObject:module];
						modules[@(item.flag)] = module;
					}
				}
				else
					charges[@(item.flag)] = item.type;
			}
		}
		
		[charges enumerateKeysAndObjectsUsingBlock:^(NSNumber* key, EVEDBInvType* obj, BOOL *stop) {
			NCLoadoutDataShipModule* module = modules[key];
			if (module)
				module.chargeID = obj.typeID;
		}];
		
		for (NCKillMailItem* item in killMail.droneBay) {
			NCLoadoutDataShipDrone* drone = dronesDic[@(item.type.typeID)];
			if (!drone) {
				drone = [NCLoadoutDataShipDrone new];
				drone.typeID = item.type.typeID;
				drone.active = true;
				dronesDic[@(item.type.typeID)] = drone;
			}
			drone.count += item.qty;
		}
		for (NCKillMailItem* item in killMail.cargo) {
			NCLoadoutDataShipCargoItem* cargo = cargoDic[@(item.type.typeID)];
			if (!cargo) {
				cargo = [NCLoadoutDataShipCargoItem new];
				cargo.typeID = item.type.typeID;
				cargoDic[@(item.type.typeID)] = cargo;
			}
			cargo.count += item.qty;
		}

		drones = [dronesDic allValues];
		cargo = [cargoDic allValues];
		
		self.loadoutData.hiSlots = hiSlots;
		self.loadoutData.medSlots = medSlots;
		self.loadoutData.lowSlots = lowSlots;
		self.loadoutData.rigSlots = rigSlots;
		self.loadoutData.subsystems = subsystems;
		self.loadoutData.drones = drones;
		self.loadoutData.cargo = cargo;
		self.loadoutData.implants = @[];
		self.loadoutData.boosters = @[];
	}
	return self;
}

- (void) flush {
	if (!self.pilot)
		return;
	
	eufe::Ship* ship = self.pilot->getShip();
	if (!ship)
		return;
	
	self.loadoutData = [NCLoadoutDataShip new];

	NSMutableArray* hiSlots = [NSMutableArray new];
	NSMutableArray* medSlots = [NSMutableArray new];
	NSMutableArray* lowSlots = [NSMutableArray new];
	NSMutableArray* rigSlots = [NSMutableArray new];
	NSMutableArray* subsystems = [NSMutableArray new];
	NSMutableArray* drones = [NSMutableArray new];
	NSMutableDictionary* dronesDic = [NSMutableDictionary new];
	NSMutableArray* cargo = [NSMutableArray new];
	NSMutableArray* implants = [NSMutableArray new];
	NSMutableArray* boosters = [NSMutableArray new];
	
	for(auto i : ship->getModules()) {
		eufe::Charge* charge = i->getCharge();
		NCLoadoutDataShipModule* module = [NCLoadoutDataShipModule new];
		module.typeID = i->getTypeID();
		module.chargeID = charge ? charge->getTypeID() : 0;
		module.state = i->getState();
		
		switch(i->getSlot()) {
			case eufe::Module::SLOT_HI:
				[hiSlots addObject:module];
				break;
			case eufe::Module::SLOT_MED:
				[medSlots addObject:module];
				break;
			case eufe::Module::SLOT_LOW:
				[lowSlots addObject:module];
				break;
			case eufe::Module::SLOT_RIG:
				[rigSlots addObject:module];
				break;
			case eufe::Module::SLOT_SUBSYSTEM:
				[subsystems addObject:module];
				break;
			default:
				break;
		}
	}
	
	for (auto i : ship->getDrones()) {
		NSString* key = [NSString stringWithFormat:@"%d:%d", i->getTypeID(), i->isActive()];
		NSDictionary* record = dronesDic[key];
		if (!record) {
			NCLoadoutDataShipDrone* drone = [NCLoadoutDataShipDrone new];
			drone.typeID = i->getTypeID();
			drone.active = i->isActive();
			drone.count = 1;
			record = @{@"drone": drone, @"order": @(dronesDic.count)};
			dronesDic[key]= record;
		}
		else {
			NCLoadoutDataShipDrone* drone = record[@"drone"];
			drone.count++;
		}
		
	}
	
	for (NSDictionary* record in [[dronesDic allValues] sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"order" ascending:YES]]])
		[drones addObject:record[@"drone"]];
	
	for (auto i : self.pilot->getImplants()) {
		NCLoadoutDataShipImplant* implant = [NCLoadoutDataShipImplant new];
		implant.typeID = i->getTypeID();
		[implants addObject:implant];
	}
	
	for (auto i : self.pilot->getBoosters()) {
		NCLoadoutDataShipBooster* booster = [NCLoadoutDataShipBooster new];
		booster.typeID = i->getTypeID();
		[boosters addObject:booster];
	}
	
	self.loadoutData.hiSlots = hiSlots;
	self.loadoutData.medSlots = medSlots;
	self.loadoutData.lowSlots = lowSlots;
	self.loadoutData.rigSlots = rigSlots;
	self.loadoutData.subsystems = subsystems;
	self.loadoutData.drones = drones;
	self.loadoutData.cargo = cargo;
	self.loadoutData.implants = implants;
	self.loadoutData.boosters = boosters;
}

- (void) save {
	[self flush];

	EVEDBInvType* type;

	eufe::Ship* ship = self.pilot ? self.pilot->getShip() : nullptr;
	if (ship)
		type = [EVEDBInvType invTypeWithTypeID:ship->getTypeID() error:nil];
	else
		type = self.loadout.type;

	NCStorage* storage = [NCStorage sharedStorage];
	if (!self.loadout) {
		[storage.managedObjectContext performBlockAndWait:^{
			self.loadout = [[NCLoadout alloc] initWithEntity:[NSEntityDescription entityForName:@"Loadout" inManagedObjectContext:storage.managedObjectContext] insertIntoManagedObjectContext:storage.managedObjectContext];
			self.loadout.data = [[NCLoadoutData alloc] initWithEntity:[NSEntityDescription entityForName:@"LoadoutData" inManagedObjectContext:storage.managedObjectContext] insertIntoManagedObjectContext:storage.managedObjectContext];
		}];
	}

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
	eufe::Ship* ship = self.pilot->setShip(self.type.typeID);
	if (ship) {
		for (NSString* key in @[@"subsystems", @"rigSlots", @"lowSlots", @"medSlots", @"hiSlots"]) {
			for (NCLoadoutDataShipModule* item in [self.loadoutData valueForKey:key]) {
				eufe::Module* module = ship->addModule(item.typeID);
				if (module) {
					module->setState(item.state);
					if (item.chargeID)
						module->setCharge(item.chargeID);
				}
			}
		}
		
		for (NCLoadoutDataShipDrone* item in self.loadoutData.drones) {
			for (int n = item.count; n > 0; n--) {
				eufe::Drone* drone = ship->addDrone(item.typeID);
				if (!drone)
					break;
				drone->setActive(item.active);
			}
		}
		
		for (NCLoadoutDataShipImplant* item in self.loadoutData.implants)
			self.pilot->addImplant(item.typeID);
		
		for (NCLoadoutDataShipBooster* item in self.loadoutData.boosters)
			self.pilot->addBooster(item.typeID);
		
		for (NCLoadoutDataShipCargoItem* item in self.loadoutData.cargo) {
			EVEDBInvType* type = [EVEDBInvType invTypeWithTypeID:item.typeID error:nil];
			if (type.group.categoryID == NCChargeCategoryID) {
				for (auto module: ship->getModules()) {
					if (!module->getCharge())
						module->setCharge(item.typeID);
				}
			}
		}
	}
}

- (void) setCharacter:(NCFitCharacter *)character {
	_character = character;
	if (self.pilot) {
		self.pilot->setCharacterName([character.name UTF8String]);
		[self setSkillLevels:character.skills];
	}
}

- (void) setPilot:(eufe::Character *)pilot {
	_pilot = pilot;
	if (self.character && pilot) {
		self.pilot->setCharacterName([self.character.name UTF8String]);
		[self setSkillLevels:self.character.skills];
	}
}

- (NSString*) canonicalName {
	[self flush];
	NSMutableArray* modules = [[NSMutableArray alloc] init];
	
	std::vector<std::pair<eufe::TypeID, eufe::TypeID> > modulePairs;
	std::map<std::pair<eufe::TypeID, eufe::TypeID>, int> moduleCounts;
	
	for (NSString* key in @[@"hiSlots", @"medSlots", @"lowSlots", @"rigSlots", @"subsystems"]) {
		for (NCLoadoutDataShipModule* item in [self.loadoutData valueForKey:key]) {
			std::pair<eufe::TypeID, eufe::TypeID> pair(item.typeID, item.chargeID);
			int count = 1;
			if (moduleCounts.find(pair) == moduleCounts.end()) {
				moduleCounts[pair] = count;
				modulePairs.push_back(pair);
			}
			else
				moduleCounts[pair] += count;
		}
	}

	std::sort(modulePairs.begin(), modulePairs.end());
	for (auto pair: modulePairs) {
		NSString* s;
		if (pair.second > 0)
			s = [NSString stringWithFormat:@"%d:%d:%d", pair.first, pair.second, moduleCounts[pair]];
		else
			s = [NSString stringWithFormat:@"%d::%d", pair.first, moduleCounts[pair]];
		[modules addObject:s];
	}
	
	NSMutableArray* drones = [[NSMutableArray alloc] init];
	std::vector<std::pair<eufe::TypeID, int> > dronePairs;
	
	for (NCLoadoutDataShipDrone* drone in self.loadoutData.drones) {
		if (!drone.active)
			continue;
		eufe::TypeID typeID = drone.typeID;
		int count = drone.count;
		dronePairs.push_back(std::pair<eufe::TypeID, int>(typeID, count));
	}
	std::sort(dronePairs.begin(), dronePairs.end());
	
	for (auto pair: dronePairs) {
		NSString* s;
		s = [NSString stringWithFormat:@"%d:%d", pair.first, pair.second];
		[drones addObject:s];
	}
	NSString* s = [NSString stringWithFormat:@"%d|%@|%@", self.type.typeID, [modules componentsJoinedByString:@";"],  [drones componentsJoinedByString:@";"]];
	return s;
}

- (NSString*) dnaRepresentation {
	[self flush];
	NSCountedSet* subsystems = [NSCountedSet set];
	NSCountedSet* hiSlots = [NSCountedSet set];
	NSCountedSet* medSlots = [NSCountedSet set];
	NSCountedSet* lowSlots = [NSCountedSet set];
	NSCountedSet* rigSlots = [NSCountedSet set];
	NSCountedSet* drones = [NSCountedSet set];
	NSCountedSet* charges = [NSCountedSet set];
	
	NSString* keys[] = {@"subsystems", @"hiSlots", @"medSlots", @"lowSlots", @"rigSlots"};
	NSCountedSet* arrays[] = {subsystems, hiSlots, medSlots, lowSlots, rigSlots};

	for (NSInteger i = 0; i < 5; i++) {
		for (NCLoadoutDataShipModule* item in [self.loadoutData valueForKey:keys[i]]) {
			if (item.chargeID)
				[charges addObject:@(item.chargeID)];
			[arrays[i] addObject:@(item.typeID)];
		}
	}
	for (NCLoadoutDataShipDrone* drone in self.loadoutData.drones) {
		NSNumber* typeID = @(drone.typeID);
		for (NSInteger i = 0; i < drone.count; i++)
			[drones addObject:typeID];
	}
	
	NSMutableString* dna = [NSMutableString stringWithFormat:@"%d:", self.type.typeID];
	
	for (NSCountedSet* set in @[subsystems, hiSlots, medSlots, lowSlots, rigSlots, drones, charges]) {
		for (NSNumber* typeID in set) {
			[dna appendFormat:@"%@;%d:", typeID, [set countForObject:typeID]];
		}
	}
	[dna appendString:@":"];

	return dna;
}

- (NSString*) eveXMLRepresentation {
	NSMutableString* xml = [NSMutableString string];
	[xml appendString:@"<?xml version=\"1.0\" ?>\n<fittings>\n"];
	[xml appendString:[self eveXMLRecordRepresentation]];
	[xml appendString:@"</fittings>"];
	return xml;
}

- (NSString*) eveXMLRecordRepresentation {
	[self flush];
	
	NSMutableString* xml = [NSMutableString stringWithFormat:@"<fitting name=\"%@\">\n<description value=\"EVEUniverse fitting engine\"/>\n<shipType value=\"%@\"/>\n", self.loadoutName, self.type.typeName];
	
	NSString* keys[] = {@"hiSlots", @"medSlots", @"lowSlots", @"rigSlots", @"subsystems"};
	NSString* slots[] = {@"hi slot", @"med slot", @"low slot", @"rig slot", @"subsystem slot"};
	
	for (NSInteger i = 0; i < 5; i++) {
		int slot = 0;
		for (NCLoadoutDataShipModule* item in [self.loadoutData valueForKey:keys[i]]) {
			EVEDBInvType* type = [EVEDBInvType invTypeWithTypeID:item.typeID error:nil];
			[xml appendFormat:@"<hardware slot=\"%@ %d\" type=\"%@\"/>\n", slots[i], slot++, type.typeName];
		}
	}
	
	for (NCLoadoutDataShipDrone* drone in self.loadoutData.drones) {
		EVEDBInvType* type = [EVEDBInvType invTypeWithTypeID:drone.typeID error:nil];
		[xml appendFormat:@"<hardware slot=\"drone bay\" qty=\"%d\" type=\"%@\"/>\n", drone.count, type.typeName];
	}
	
	[xml appendString:@"</fitting>\n"];
	return xml;
}

- (NSString*) eftRepresentation {
	NSMutableString* eft = [NSMutableString stringWithFormat:@"[%@, %@]\n", self.loadoutName, self.type.typeName];
	
	for (NSString* key in @[@"lowSlots", @"medSlots", @"hiSlots", @"rigSlots", @"subsystems"]) {
		NSArray* array = [self.loadoutData valueForKey:key];
		if (array.count == 0)
			continue;
		for (NCLoadoutDataShipModule* item in array) {
			EVEDBInvType* type = [EVEDBInvType invTypeWithTypeID:item.typeID error:nil];
			if (item.chargeID) {
				EVEDBInvType* charge = [EVEDBInvType invTypeWithTypeID:item.chargeID error:nil];
				[eft appendFormat:@"%@, %@\n", type.typeName, charge.typeName];
			}
			else
				[eft appendFormat:@"%@\n", type.typeName];
		}
		[eft appendString:@"\n"];
	}

	for (NCLoadoutDataShipDrone* item in self.loadoutData.drones) {
		EVEDBInvType* type = [EVEDBInvType invTypeWithTypeID:item.typeID error:nil];
		[eft appendFormat:@"%@ x%d\n", type.typeName, item.count];
	}
	return eft;
}

- (NSString*) hyperlinkTag {
	NSString* dna = self.dnaRepresentation;
	return [NSString stringWithFormat:@"<a href=\"javascript:if (typeof CCPEVE != 'undefined') CCPEVE.showFitting('%@'); else window.open('fitting:%@');\">%@ - %@</a>", dna, dna, self.type.typeName, self.loadoutName];
}

#pragma mark - Private

- (void) setSkillLevels:(NSDictionary*) skillLevels {
	__block std::map<eufe::TypeID, int> levels;
	[skillLevels enumerateKeysAndObjectsUsingBlock:^(NSNumber* typeID, NSNumber* level, BOOL *stop) {
		levels[[typeID integerValue]] = [level integerValue];
	}];
	self.pilot->setSkillLevels(levels);

}


@end