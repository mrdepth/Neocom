//
//  NCSpaceStructureFit.m
//  Neocom
//
//  Created by Артем Шиманский on 14.03.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCSpaceStructureFit.h"
#import "NCDatabase.h"

@implementation NCLoadoutDataSpaceStructure

- (id) initWithCoder:(NSCoder *)aDecoder {
	if (self = [super init]) {
		self.hiSlots = [aDecoder decodeObjectForKey:@"hiSlots"];
		self.medSlots = [aDecoder decodeObjectForKey:@"medSlots"];
		self.lowSlots = [aDecoder decodeObjectForKey:@"lowSlots"];
		self.rigSlots = [aDecoder decodeObjectForKey:@"rigSlots"];
		self.services = [aDecoder decodeObjectForKey:@"services"];
		self.drones = [aDecoder decodeObjectForKey:@"drones"];
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
	if (self.services)
		[aCoder encodeObject:self.services forKey:@"services"];
	if (self.drones)
		[aCoder encodeObject:self.drones forKey:@"drones"];
	
}

- (BOOL) isEqual:(id)object {
	if (![object isKindOfClass:[self class]])
		return NO;
	for (NSString* key in @[@"hiSlots", @"medSlots", @"lowSlots", @"rigSlots", @"services", @"drones"]) {
		NSArray* a = [self valueForKey:key];
		NSArray* b = [object valueForKey:key];
		if (a != b && ![a isEqualToArray:b])
			return NO;
	}
	return YES;
}

@end

@implementation NCLoadoutDataSpaceStructureModule

- (id) initWithCoder:(NSCoder *)aDecoder {
	if (self = [super init]) {
		self.typeID = [aDecoder decodeInt32ForKey:@"typeID"];
		self.chargeID = [aDecoder decodeInt32ForKey:@"chargeID"];
		self.state = static_cast<dgmpp::Module::State>([aDecoder decodeInt32ForKey:@"state"]);
	}
	return self;
}

- (void) encodeWithCoder:(NSCoder *)aCoder {
	[aCoder encodeInt32:self.typeID forKey:@"typeID"];
	[aCoder encodeInt32:self.chargeID forKey:@"chargeID"];
	[aCoder encodeInt32:self.state forKey:@"state"];
}

- (BOOL) isEqual:(NCLoadoutDataSpaceStructureModule*)object {
	return [object isKindOfClass:[self class]] && self.typeID == object.typeID && self.chargeID == object.chargeID && self.state == object.state;
}

@end

@implementation NCLoadoutDataSpaceStructureDrone

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

- (BOOL) isEqual:(NCLoadoutDataSpaceStructureDrone*)object {
	return [object isKindOfClass:[self class]] && self.typeID == object.typeID && self.count == object.count && self.active == object.active;
}

@end

@interface NCSpaceStructureFit()
@property (nonatomic, strong, readwrite) NCFittingEngine* engine;
@property (nonatomic, assign, readwrite) int32_t typeID;
@property (nonatomic, strong, readwrite) NSManagedObjectID* loadoutID;

@property (nonatomic, assign, readwrite) std::shared_ptr<dgmpp::Character> pilot;

@property (nonatomic, strong) NCLoadoutDataSpaceStructure* loadoutData;
@property (nonatomic, strong) NSManagedObjectContext* storageManagedObjectContext;
@property (nonatomic, strong) NSManagedObjectContext* databaseManagedObjectContext;

- (void) setSkillLevels:(NSDictionary*) skillLevels;
- (void) saveWithCompletionBlock:(void(^)()) completionBlock;
@end

@implementation NCSpaceStructureFit

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

- (void) flush {
	if (self.engine) {
		[self.engine performBlockAndWait:^{
			if (!self.pilot)
				return;
			auto spaceStructure = self.pilot->getSpaceStructure();
			if (!spaceStructure)
				return;

			self.loadoutData = [NCLoadoutDataSpaceStructure new];
			
			NSMutableArray* hiSlots = [NSMutableArray new];
			NSMutableArray* medSlots = [NSMutableArray new];
			NSMutableArray* lowSlots = [NSMutableArray new];
			NSMutableArray* rigSlots = [NSMutableArray new];
			NSMutableArray* services = [NSMutableArray new];
			NSMutableArray* drones = [NSMutableArray new];
			NSMutableDictionary* dronesDic = [NSMutableDictionary new];
			
			for(auto i : spaceStructure->getModules()) {
				auto charge = i->getCharge();
				NCLoadoutDataSpaceStructureModule* module = [NCLoadoutDataSpaceStructureModule new];
				module.typeID = i->getTypeID();
				module.chargeID = charge ? charge->getTypeID() : 0;
				module.state = i->getPreferredState();
				
				switch(i->getSlot()) {
					case dgmpp::Module::SLOT_HI:
						[hiSlots addObject:module];
						break;
					case dgmpp::Module::SLOT_MED:
						[medSlots addObject:module];
						break;
					case dgmpp::Module::SLOT_LOW:
						[lowSlots addObject:module];
						break;
					case dgmpp::Module::SLOT_RIG:
						[rigSlots addObject:module];
						break;
					case dgmpp::Module::SLOT_SERVICE:
						[services addObject:module];
						break;
					default:
						break;
				}
			}
			
			for (const auto& i : spaceStructure->getDrones()) {
				NSString* key = [NSString stringWithFormat:@"%d:%d", i->getTypeID(), i->isActive()];
				NSDictionary* record = dronesDic[key];
				if (!record) {
					NCLoadoutDataSpaceStructureDrone* drone = [NCLoadoutDataSpaceStructureDrone new];
					drone.typeID = i->getTypeID();
					drone.active = i->isActive();
					drone.count = 1;
					record = @{@"drone": drone, @"order": @(dronesDic.count)};
					dronesDic[key]= record;
				}
				else {
					NCLoadoutDataSpaceStructureDrone* drone = record[@"drone"];
					drone.count++;
				}
				
			}
			
			for (NSDictionary* record in [[dronesDic allValues] sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"order" ascending:YES]]])
				[drones addObject:record[@"drone"]];
			
			self.loadoutData.hiSlots = hiSlots;
			self.loadoutData.medSlots = medSlots;
			self.loadoutData.lowSlots = lowSlots;
			self.loadoutData.rigSlots = rigSlots;
			self.loadoutData.services = services;
			self.loadoutData.drones = drones;
		}];
	}
	else {
		NCFittingEngine* engine = [NCFittingEngine new];
		self.loadoutData = [engine loadoutDataSpaceStructureWithFit:self];
	}
}

- (void) save {
	[self saveWithCompletionBlock:nil];
}

- (void) duplicateWithCompletioBloc:(void(^)()) completionBlock {
	[self saveWithCompletionBlock:^{
		self.loadoutID = nil;
		self.loadoutName = [NSString stringWithFormat:NSLocalizedString(@"%@ copy", nil), self.loadoutName ? self.loadoutName : @""];
		[self saveWithCompletionBlock:^{
			if (completionBlock)
				completionBlock();
		}];
	}];
}

- (void) setCharacter:(NCFitCharacter*) character withCompletionBlock:(void(^)()) completionBlock {
	BOOL loadCharacterImplants = [[NSUserDefaults standardUserDefaults] boolForKey:NCSettingsLoadCharacterImplantsKey];
	NSAssert(self.pilot, @"Pilot is nil");
	_character = character;
	
	__block NSDictionary* skills;
	__block NSArray* implants;
	__block NSString* characterName;
	
	void (^load)() = ^{
		[self.engine performBlock:^{
			[self setSkillLevels:skills];
			if (loadCharacterImplants) {
				for (NSNumber* implantID in implants)
					self.pilot->addImplant([implantID intValue]);
			}
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


#pragma mark - Private

- (void) setSkillLevels:(NSDictionary*) skillLevels {
	__block std::map<dgmpp::TypeID, int32_t> levels;
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

- (void) saveWithCompletionBlock:(void(^)()) completionBlock {
	[self flush];
	
	int32_t typeID = self.typeID;
	
	NSManagedObjectContext* context = self.storageManagedObjectContext;
	NSManagedObjectID* loadoutID = self.loadoutID;
	NSString* loadoutName = self.loadoutName;
	[context performBlock:^{
		NCLoadout* loadout;
		if (!loadoutID) {
			loadout = [[NCLoadout alloc] initWithEntity:[NSEntityDescription entityForName:@"Loadout" inManagedObjectContext:context] insertIntoManagedObjectContext:context];
			loadout.data = [[NCLoadoutData alloc] initWithEntity:[NSEntityDescription entityForName:@"LoadoutData" inManagedObjectContext:context] insertIntoManagedObjectContext:context];
		}
		else
			loadout = [self.storageManagedObjectContext existingObjectWithID:loadoutID error:nil];
		
		if (![loadout.data.data isEqual:self.loadoutData])
			loadout.data.data = self.loadoutData;
		if (loadout.typeID != typeID)
			loadout.typeID = typeID;
		if (![loadoutName isEqualToString:loadout.name])
			loadout.name = loadoutName;
		if ([context hasChanges]) {
			[context save:nil];
			dispatch_async(dispatch_get_main_queue(), ^{
				self.loadoutID = loadout.objectID;
				if (completionBlock)
					completionBlock();
			});
		}
		else {
			if (completionBlock)
				dispatch_async(dispatch_get_main_queue(), ^{
					completionBlock();
				});
		}
	}];
}

@end