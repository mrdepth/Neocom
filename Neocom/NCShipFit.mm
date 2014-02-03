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

#define NCChargeCategoryID 9

@interface NCLoadoutDataShip : NSObject<NSCoding>
@property (nonatomic, strong) NSArray* hiSlots;
@property (nonatomic, strong) NSArray* medSlots;
@property (nonatomic, strong) NSArray* lowSlots;
@property (nonatomic, strong) NSArray* rigSlots;
@property (nonatomic, strong) NSArray* subsystems;
@property (nonatomic, strong) NSArray* drones;
@property (nonatomic, strong) NSArray* cargo;
@property (nonatomic, strong) NSArray* implants;
@property (nonatomic, strong) NSArray* boosters;
@end

@interface NCLoadoutDataShipModule : NSObject<NSCoding>
@property (nonatomic, assign) eufe::TypeID typeID;
@property (nonatomic, assign) eufe::TypeID chargeID;
@property (nonatomic, assign) eufe::Module::State state;
@end

@interface NCLoadoutDataShipDrone : NSObject<NSCoding>
@property (nonatomic, assign) eufe::TypeID typeID;
@property (nonatomic, assign) int32_t count;
@property (nonatomic, assign) bool active;
@end

@interface NCLoadoutDataShipImplant : NSObject<NSCoding>
@property (nonatomic, assign) eufe::TypeID typeID;
@end

@interface NCLoadoutDataShipBooster : NSObject<NSCoding>
@property (nonatomic, assign) eufe::TypeID typeID;
@end

@interface NCLoadoutDataShipCargoItem : NSObject<NSCoding>
@property (nonatomic, assign) eufe::TypeID typeID;
@property (nonatomic, assign) int32_t count;
@end

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
			self.loadoutName = loadout.loadoutName;
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


- (void) save {
	if (!self.pilot)
		return;
	
	eufe::Ship* ship = self.pilot->getShip();
	if (!ship)
		return;
	
	NCStorage* storage = [NCStorage sharedStorage];
	if (!self.loadout) {
		[storage.managedObjectContext performBlockAndWait:^{
			self.loadout = [[NCLoadout alloc] initWithEntity:[NSEntityDescription entityForName:@"Loadout" inManagedObjectContext:storage.managedObjectContext] insertIntoManagedObjectContext:storage.managedObjectContext];
			self.loadout.data = [[NCLoadoutData alloc] initWithEntity:[NSEntityDescription entityForName:@"LoadoutData" inManagedObjectContext:storage.managedObjectContext] insertIntoManagedObjectContext:storage.managedObjectContext];
		}];
	}
	self.loadoutData = [NCLoadoutDataShip new];

	EVEDBInvType* type = nil;
	
	type = [EVEDBInvType invTypeWithTypeID:ship->getTypeID() error:nil];
	
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
	
	[storage.managedObjectContext performBlockAndWait:^{
		if (![self.loadout.data.data isEqual:self.loadoutData])
			self.loadout.data.data = self.loadoutData;
		if (self.loadout.typeID != type.typeID)
			self.loadout.typeID = type.typeID;
		if (![self.loadoutName isEqualToString:self.loadout.loadoutName])
			self.loadout.loadoutName = self.loadoutName;
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

#pragma mark - Private

- (void) setSkillLevels:(NSDictionary*) skillLevels {
	__block std::map<eufe::TypeID, int> levels;
	[skillLevels enumerateKeysAndObjectsUsingBlock:^(NSNumber* typeID, NSNumber* level, BOOL *stop) {
		levels[[typeID integerValue]] = [level integerValue];
	}];
	self.pilot->setSkillLevels(levels);

}


@end