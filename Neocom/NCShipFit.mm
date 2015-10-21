//
//  NCShipFit.m
//  Neocom
//
//  Created by Артем Шиманский on 31.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCShipFit.h"
#import "NCStorage.h"
//#import "BattleClinicAPI.h"
//#import "NeocomAPI.h"
#import <EVEAPI/EVEAPI.h>
#import "EVEAssetListItem+Neocom.h"
#import "NCKillMail.h"
#import "NCDatabase.h"

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
		self.mode = [aDecoder decodeInt32ForKey:@"mode"];
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
	if (self.mode)
		[aCoder encodeInt32:self.mode forKey:@"mode"];
	
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
	if (self.mode != [[object valueForKey:@"mode"] intValue])
		return NO;
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

- (BOOL) isEqual:(NCLoadoutDataShipModule*)object {
	return [object isKindOfClass:[self class]] && self.typeID == object.typeID && self.chargeID == object.chargeID && self.state == object.state;
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

- (BOOL) isEqual:(NCLoadoutDataShipDrone*)object {
	return [object isKindOfClass:[self class]] && self.typeID == object.typeID && self.count == object.count && self.active == object.active;
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

- (BOOL) isEqual:(NCLoadoutDataShipImplant*)object {
	return [object isKindOfClass:[self class]] && self.typeID == object.typeID;
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

- (BOOL) isEqual:(NCLoadoutDataShipBooster*)object {
	return [object isKindOfClass:[self class]] && self.typeID == object.typeID;
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

- (BOOL) isEqual:(NCLoadoutDataShipCargoItem*)object {
	return [object isKindOfClass:[self class]] && self.typeID == object.typeID && self.count == object.count;
}

@end


@interface NCShipFit()
@property (nonatomic, strong, readwrite) NCFittingEngine* engine;
//@property (nonatomic, strong, readwrite) NCLoadout* loadout;
@property (nonatomic, assign, readwrite) int32_t typeID;
@property (nonatomic, strong, readwrite) NSManagedObjectID* loadoutID;
@property (nonatomic, strong, readwrite) NAPISearchItem* apiLadout;
@property (nonatomic, strong, readwrite) EVEAssetListItem* asset;
@property (nonatomic, strong, readwrite) NCKillMail* killMail;
@property (nonatomic, strong, readwrite) NSString* dna;

@property (nonatomic, assign, readwrite) std::shared_ptr<eufe::Character> pilot;

@property (nonatomic, strong) NCLoadoutDataShip* loadoutData;
@property (nonatomic, strong) NSManagedObjectContext* storageManagedObjectContext;
@property (nonatomic, strong) NSManagedObjectContext* databaseManagedObjectContext;
- (void) setSkillLevels:(NSDictionary*) skillLevels;
@end

@implementation NCShipFit
@synthesize character = _character;

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

- (id) initWithAPILoadout:(NAPISearchItem *)apiLoadout {
	if (self = [super init]) {
		self.apiLadout = apiLoadout;
		self.loadoutName = apiLoadout.typeName;
		self.typeID = apiLoadout.typeID;
	}
	return self;
}

- (id) initWithAsset:(EVEAssetListItem *)asset {
	if (self = [super init]) {
		self.asset = asset;
		self.typeID = asset.typeID;
		self.loadoutName = asset.location.itemName ?: asset.typeName;
	}
	return self;
}

- (id) initWithKillMail:(NCKillMail*) killMail {
	if (self = [super init]) {
		self.killMail = killMail;
		self.typeID = killMail.victim.shipTypeID;
		[self.databaseManagedObjectContext performBlockAndWait:^{
			NCDBInvType* type = [self.databaseManagedObjectContext invTypeWithTypeID:killMail.victim.shipTypeID];
			self.loadoutName = [NSString stringWithFormat:@"%@ - %@", type.typeName , killMail.victim.characterName];
		}];
	}
	return self;
}

- (id) initWithDNA:(NSString *)dna {
	if (self = [super init]) {
		self.dna = dna;
		[self.databaseManagedObjectContext performBlockAndWait:^{
			NSArray* records = [dna componentsSeparatedByString:@":"];
			if (records.count > 0) {
				int32_t shipTypeID = [records[0] intValue];
				if (shipTypeID) {
					NCDBInvType* type = [self.databaseManagedObjectContext invTypeWithTypeID:shipTypeID];
					self.typeID = shipTypeID;
					self.loadoutName = type.typeName;
				}
			}
		}];
	}
	return self;
}

/*- (id) initWithBattleClinicLoadout:(BCEveLoadout*) bcLoadout {
	if (self = [super init]) {
		NSMutableArray* components = [NSMutableArray arrayWithArray:[bcLoadout.fitting componentsSeparatedByString:@":"]];
		[components removeObjectAtIndex:0];
		int32_t shipID = [components[0] intValue];
		
		if (!shipID)
			return nil;
		else {
			[components removeObjectAtIndex:0];
			self.type = [NCDBInvType invTypeWithTypeID:shipID];
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
				int32_t typeID = [[fields objectAtIndex:0] intValue];
				int32_t amount = fields.count > 1 ? [[fields objectAtIndex:1] intValue] : 1;
				NCDBInvType *type = [NCDBInvType invTypeWithTypeID:typeID];
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
			int32_t shipID = [components[0] intValue];
			
			self.type = [NCDBInvType invTypeWithTypeID:shipID];
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
					eufe::TypeID typeID = array.count > 0 ? [array[0] intValue] : 0;
					eufe::TypeID chargeID = array.count > 1 ? [array[1] intValue] : 0;
					int32_t count = array.count > 2 ? [array[2] intValue] : 1;
					if (!typeID)
						continue;
					
					NCDBInvType *type = [NCDBInvType invTypeWithTypeID:typeID];
					
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
					eufe::TypeID typeID = array.count > 0 ? [array[0] intValue] : 0;
					int32_t count = array.count > 1 ? [array[1] intValue] : 0;
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
					eufe::TypeID typeID = [component intValue];
					if (typeID) {
						NCLoadoutDataShipImplant* implant = [NCLoadoutDataShipImplant new];
						implant.typeID = typeID;
						[implants addObject:implant];
					}
				}
			}
			
			if (components.count > 4) {
				for (NSString* component in [components[4] componentsSeparatedByString:@";"]) {
					eufe::TypeID typeID = [component intValue];
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
		self.type = [NCDBInvType invTypeWithTypeID:asset.typeID];
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
		
		[charges enumerateKeysAndObjectsUsingBlock:^(NSNumber* key, NCDBInvType* obj, BOOL *stop) {
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

- (id) initWithDNA:(NSString *)dna {
	if (self = [super init]) {
		NSMutableArray* records = [[dna componentsSeparatedByString:@":"] mutableCopy];
		if (records.count == 0) {
			return nil;
		}
		int32_t shipTypeID = [records[0] intValue];
		if (!shipTypeID)
			return nil;
		self.type = [NCDBInvType invTypeWithTypeID:shipTypeID];
		if (!self.type)
			return nil;
			
		self.loadoutName = self.type.typeName;
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
		
		for (NSString* record in records) {
			NSArray* components = [record componentsSeparatedByString:@";"];
			int32_t typeID = 0;
			int32_t amount = 1;
			
			if (components.count > 0)
				typeID = [[components objectAtIndex:0] intValue];
			if (components.count > 1)
				amount = [[components objectAtIndex:1] intValue];
			
			if (amount > 0) {
				NCDBInvType* type = [NCDBInvType invTypeWithTypeID:typeID];
				
				
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
}*/


- (void) flush {
	[self.engine performBlockAndWait:^{
		if (!self.pilot)
			return;

		auto ship = self.pilot->getShip();
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
		eufe::TypeID modeID = 0;
		
		for(auto i : ship->getModules()) {
			auto charge = i->getCharge();
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
				case eufe::Module::SLOT_MODE:
					modeID = module.typeID;
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
		self.loadoutData.mode = modeID;
	}];
}

- (void) save {
	[self flush];

	__block int32_t typeID = self.typeID;
	
	[self.engine performBlockAndWait:^{
		if (self.pilot) {
			auto ship = self.pilot->getShip();
			if (ship)
				typeID = ship->getTypeID();
		}
	}];
	
	NSManagedObjectContext* context = self.storageManagedObjectContext;
	[context performBlock:^{
		NCLoadout* loadout;
		if (!self.loadoutID) {
			loadout = [[NCLoadout alloc] initWithEntity:[NSEntityDescription entityForName:@"Loadout" inManagedObjectContext:context] insertIntoManagedObjectContext:context];
			loadout.data = [[NCLoadoutData alloc] initWithEntity:[NSEntityDescription entityForName:@"LoadoutData" inManagedObjectContext:context] insertIntoManagedObjectContext:context];
		}
		else
			loadout = [self.storageManagedObjectContext existingObjectWithID:self.loadoutID error:nil];

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
}

/*- (void) load {
	[self.databaseManagedObjectContext performBlockAndWait:^{
		[self.engine performBlockAndWait:^{
			auto ship = self.pilot->setShip(self.typeID);
			if (ship) {
				for (NSString* key in @[@"subsystems", @"rigSlots", @"lowSlots", @"medSlots", @"hiSlots"]) {
					for (NCLoadoutDataShipModule* item in [self.loadoutData valueForKey:key]) {
						auto module = ship->addModule(item.typeID);
						if (module) {
							module->setState(item.state);
							if (item.chargeID)
								module->setCharge(item.chargeID);
						}
					}
				}
				
				for (NCLoadoutDataShipDrone* item in self.loadoutData.drones) {
					for (int n = item.count; n > 0; n--) {
						auto drone = ship->addDrone(item.typeID);
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
					NCDBInvType* type = [self.databaseManagedObjectContext invTypeWithTypeID:item.typeID];
					if (type.group.category.categoryID == NCChargeCategoryID) {
						for (auto module: ship->getModules()) {
							if (!module->getCharge())
								module->setCharge(item.typeID);
						}
					}
				}
				
				if (ship->getFreeSlots(eufe::Module::SLOT_MODE) > 0) {
					eufe::TypeID modeID = self.loadoutData.mode;
					if (!modeID) {
						NCDBEufeItemCategory* category = [self.databaseManagedObjectContext categoryWithSlot:NCDBEufeItemSlotMode size:ship->getTypeID() race:nil];
						NCDBEufeItemGroup* group = [category.itemGroups anyObject];
						NCDBEufeItem* item = [group.items anyObject];
						modeID = item.type.typeID;
					}
					if (modeID > 0)
						ship->addModule(modeID);
				}
			}
		}];
	}];
}*/

- (void) setCharacter:(NCFitCharacter*) character withCompletionBlock:(void(^)()) completionBlock {
	NSAssert(self.pilot, @"Pilot is nil");
	_character = character;
	
	__block NSDictionary* skills;
	__block NSArray* implants;
	__block NSString* characterName;
	
	void (^load)() = ^{
		[self.engine performBlock:^{
			[self setSkillLevels:skills];
			for (NSNumber* implantID in implants)
				self.pilot->addImplant([implantID intValue]);
			self.pilot->setCharacterName([characterName cStringUsingEncoding:NSUTF8StringEncoding]);
			if (completionBlock)
				dispatch_async(dispatch_get_main_queue(), completionBlock);
		}];
	};
	if (character.managedObjectContext)
		[character.managedObjectContext performBlockAndWait:^{
			skills = character.skills;
			implants = character.implants;
			characterName = character.name;
			load();
		}];
	else {
		skills = character.skills;
		implants = character.implants;
		characterName = character.name;
		load();
	}
}

/*- (void) setPilot:(eufe::Character *)pilot {
	_pilot = pilot;
	if (self.character && pilot) {
		__block NSDictionary* skills;
		__block NSArray* implants;
		[self.character.managedObjectContext performBlockAndWait:^{
			skills = self.character.skills;
			implants = self.character.implants;
		}];
		[self.engine performBlockAndWait:^{
			[self setSkillLevels:skills];
			for (NSNumber* implantID in implants)
				self.pilot->addImplant([implantID intValue]);
		}];
	}
}*/

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
	NSString* s = [NSString stringWithFormat:@"%d|%@|%@", self.typeID, [modules componentsJoinedByString:@";"],  [drones componentsJoinedByString:@";"]];
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
	
	NSMutableString* dna = [NSMutableString stringWithFormat:@"%d:", self.typeID];
	
	for (NSCountedSet* set in @[subsystems, hiSlots, medSlots, lowSlots, rigSlots, drones, charges]) {
		for (NSNumber* typeID in set) {
			[dna appendFormat:@"%@;%d:", typeID, (int32_t) [set countForObject:typeID]];
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
	NSMutableString* xml = [NSMutableString new];
	[self.databaseManagedObjectContext performBlockAndWait:^{
		NCDBInvType* type = [self.databaseManagedObjectContext invTypeWithTypeID:self.typeID];
		[xml appendFormat:@"<fitting name=\"%@\">\n<description value=\"Neocom\"/>\n<shipType value=\"%@\"/>\n", self.loadoutName, type.typeName];
		
		NSString* keys[] = {@"hiSlots", @"medSlots", @"lowSlots", @"rigSlots", @"subsystems"};
		NSString* slots[] = {@"hi slot", @"med slot", @"low slot", @"rig slot", @"subsystem slot"};
		
		for (NSInteger i = 0; i < 5; i++) {
			int slot = 0;
			for (NCLoadoutDataShipModule* item in [self.loadoutData valueForKey:keys[i]]) {
				NCDBInvType* type = [self.databaseManagedObjectContext invTypeWithTypeID:item.typeID];
				[xml appendFormat:@"<hardware slot=\"%@ %d\" type=\"%@\"/>\n", slots[i], slot++, type.typeName];
			}
		}
		
		for (NCLoadoutDataShipDrone* drone in self.loadoutData.drones) {
			NCDBInvType* type = [self.databaseManagedObjectContext invTypeWithTypeID:drone.typeID];
			[xml appendFormat:@"<hardware slot=\"drone bay\" qty=\"%d\" type=\"%@\"/>\n", drone.count, type.typeName];
		}
		
		[xml appendString:@"</fitting>\n"];
	}];
	return xml;
}

- (NSString*) eftRepresentation {
	NSMutableString* eft = [NSMutableString new];
	[self.databaseManagedObjectContext performBlockAndWait:^{
		NCDBInvType* type = [self.databaseManagedObjectContext invTypeWithTypeID:self.typeID];
		[NSMutableString stringWithFormat:@"[%@, %@]\n", type.typeName, self.loadoutName];
		
		for (NSString* key in @[@"lowSlots", @"medSlots", @"hiSlots", @"rigSlots", @"subsystems"]) {
			NSArray* array = [self.loadoutData valueForKey:key];
			if (array.count == 0)
				continue;
			for (NCLoadoutDataShipModule* item in array) {
				NCDBInvType* type = [self.databaseManagedObjectContext invTypeWithTypeID:item.typeID];
				if (item.chargeID) {
					NCDBInvType* charge = [self.databaseManagedObjectContext invTypeWithTypeID:item.chargeID];
					[eft appendFormat:@"%@, %@\n", type.typeName, charge.typeName];
				}
				else
					[eft appendFormat:@"%@\n", type.typeName];
			}
			[eft appendString:@"\n"];
		}
		
		for (NCLoadoutDataShipDrone* item in self.loadoutData.drones) {
			NCDBInvType* type = [self.databaseManagedObjectContext invTypeWithTypeID:item.typeID];
			[eft appendFormat:@"%@ x%d\n", type.typeName, item.count];
		}
	}];
	return eft;
}

- (NSString*) hyperlinkTag {
	__block NSString* hyperlinkTag;
	[self.databaseManagedObjectContext performBlockAndWait:^{
		NSString* dna = self.dnaRepresentation;
		NCDBInvType* type = [self.databaseManagedObjectContext invTypeWithTypeID:self.typeID];
		hyperlinkTag = [NSString stringWithFormat:@"<a href=\"javascript:if (typeof CCPEVE != 'undefined') CCPEVE.showFitting('%@'); else window.open('fitting:%@');\">%@ - %@</a>", dna, dna, type.typeName, self.loadoutName];;
	}];
	return hyperlinkTag;
}

#pragma mark - Private

- (void) setSkillLevels:(NSDictionary*) skillLevels {
	__block std::map<eufe::TypeID, int32_t> levels;
	[skillLevels enumerateKeysAndObjectsUsingBlock:^(NSNumber* typeID, NSNumber* level, BOOL *stop) {
		levels[[typeID intValue]] = [level intValue];
	}];
	self.pilot->setSkillLevels(levels);
}

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