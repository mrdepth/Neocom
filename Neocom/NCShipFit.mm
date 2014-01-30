//
//  NCShipFit.m
//  Neocom
//
//  Created by Artem Shimanski on 17.12.13.
//  Copyright (c) 2013 Artem Shimanski. All rights reserved.
//

#import "NCShipFit.h"
#import "NCStorage.h"
#import "EVEDBAPI.h"

@implementation NCShipFitLoadout

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
		if (a != b && [a isEqualToArray:b])
			return NO;
	}
	return YES;
}

@end

@implementation NCShipFitLoadoutModule

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

@implementation NCShipFitLoadoutDrone

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

@implementation NCShipFitLoadoutImplant

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

@implementation NCShipFitLoadoutBooster

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

@implementation NCShipFitLoadoutCargoItem

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


@implementation NCShipFit

@dynamic loadout;

+ (NSArray*) allFits {
	NCStorage* storage = [NCStorage sharedStorage];
	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
	[fetchRequest setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"typeName" ascending:YES]]];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"ShipFit" inManagedObjectContext:storage.managedObjectContext];
	[fetchRequest setEntity:entity];
	
	NSError *error = nil;
	NSArray *fetchedObjects = [storage.managedObjectContext executeFetchRequest:fetchRequest error:&error];
	return fetchedObjects;
}

+ (instancetype) emptyFit {
	NCStorage* storage = [NCStorage sharedStorage];
	NCShipFit* fit = [[NCShipFit alloc] initWithEntity:[NSEntityDescription entityForName:@"ShipFit"
																   inManagedObjectContext:storage.managedObjectContext]
						insertIntoManagedObjectContext:nil];
	fit.loadout = [[NCFitLoadout alloc] initWithEntity:[NSEntityDescription entityForName:@"FitLoadout"
																	   inManagedObjectContext:storage.managedObjectContext]
							insertIntoManagedObjectContext:nil];
	return fit;
}

- (void) saveFromCharacter:(eufe::Character*) character {
	eufe::Ship* ship = character->getShip();
	NCShipFitLoadout* loadout = [NCShipFitLoadout new];

	if (ship) {
		EVEDBInvType* type = [EVEDBInvType invTypeWithTypeID:ship->getTypeID() error:nil];
		self.typeID = ship->getTypeID();
		self.typeName = type.typeName;
		self.imageName = [type typeSmallImageName];
		
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
			NCShipFitLoadoutModule* module = [NCShipFitLoadoutModule new];
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
				NCShipFitLoadoutDrone* drone = [NCShipFitLoadoutDrone new];
				drone.typeID = i->getTypeID();
				drone.active = i->isActive();
				drone.count = 1;
				record = @{@"drone": drone, @"order": @(dronesDic.count)};
				dronesDic[key]= record;
			}
			else {
				NCShipFitLoadoutDrone* drone = record[@"drone"];
				drone.count++;
			}

		}
		
		for (NSDictionary* record in [[dronesDic allValues] sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"order" ascending:YES]]])
			[drones addObject:record[@"drone"]];

		for (auto i : character->getImplants()) {
			NCShipFitLoadoutImplant* implant = [NCShipFitLoadoutImplant new];
			implant.typeID = i->getTypeID();
			[implants addObject:implant];
		}
		
		for (auto i : character->getBoosters()) {
			NCShipFitLoadoutBooster* booster = [NCShipFitLoadoutBooster new];
			booster.typeID = i->getTypeID();
			[boosters addObject:booster];
		}
		loadout.hiSlots = hiSlots;
		loadout.medSlots = medSlots;
		loadout.lowSlots = lowSlots;
		loadout.rigSlots = rigSlots;
		loadout.subsystems = subsystems;
		loadout.drones = drones;
		loadout.cargo = cargo;
		loadout.implants = implants;
		loadout.boosters = boosters;
	}
	else {
		self.typeID = 0;
		self.typeName = nil;
		self.imageName = nil;
	}
	
	if (![self.loadout.loadout isEqual:loadout])
		self.loadout.loadout = loadout;
}

- (void) loadToCharacter:(eufe::Character*) character {
	NCShipFitLoadout* loadout = self.loadout.loadout;
	eufe::Ship* ship = character->setShip(self.typeID);
	if (ship) {
		for (NSString* key in @[@"subsystems", @"rigSlots", @"lowSlots", @"medSlots", @"hiSlots"]) {
			for (NCShipFitLoadoutModule* item in [loadout valueForKey:key]) {
				eufe::Module* module = ship->addModule(item.typeID);
				if (module) {
					module->setState(item.state);
					if (item.chargeID)
						module->setCharge(item.chargeID);
				}
			}
		}
		
		for (NCShipFitLoadoutDrone* item in loadout.drones) {
			for (int n = item.count; n > 0; n--) {
				eufe::Drone* drone = ship->addDrone(item.typeID);
				if (!drone)
					break;
				drone->setActive(item.active);
			}
		}
		
		for (NCShipFitLoadoutImplant* item in loadout.implants)
			character->addImplant(item.typeID);

		for (NCShipFitLoadoutImplant* item in loadout.boosters)
			character->addBooster(item.typeID);
	}
}

@end
