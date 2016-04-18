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
		self.state = static_cast<dgmpp::Module::State>([aDecoder decodeInt32ForKey:@"state"]);
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
@property (nonatomic, strong, readwrite) CRFitting* crFitting;

@property (nonatomic, assign, readwrite) std::shared_ptr<dgmpp::Character> pilot;

@property (nonatomic, strong) NCLoadoutDataShip* loadoutData;
@property (nonatomic, strong) NSManagedObjectContext* storageManagedObjectContext;
@property (nonatomic, strong) NSManagedObjectContext* databaseManagedObjectContext;
- (void) setSkillLevels:(NSDictionary*) skillLevels;
- (void) saveWithCompletionBlock:(void(^)()) completionBlock;
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

- (id) initWithCRFitting:(CRFitting *)fitting {
	if (self = [super init]) {
		self.crFitting = fitting;
		self.typeID = fitting.ship.typeID;
		self.loadoutName = fitting.name;
	}
	return self;
}

- (void) flush {
	if (self.engine) {
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
			dgmpp::TypeID modeID = 0;
			
			for(auto i : ship->getModules()) {
				auto charge = i->getCharge();
				NCLoadoutDataShipModule* module = [NCLoadoutDataShipModule new];
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
					case dgmpp::Module::SLOT_SUBSYSTEM:
						[subsystems addObject:module];
						break;
					case dgmpp::Module::SLOT_MODE:
						modeID = module.typeID;
						break;
					default:
						break;
				}
			}
			
			for (const auto& i : ship->getDrones()) {
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
			
			for (const auto& i : self.pilot->getImplants()) {
				NCLoadoutDataShipImplant* implant = [NCLoadoutDataShipImplant new];
				implant.typeID = i->getTypeID();
				[implants addObject:implant];
			}
			
			for (const auto& i : self.pilot->getBoosters()) {
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
	else {
		NCFittingEngine* engine = [NCFittingEngine new];
		self.loadoutData = [engine loadoutDataShipWithFit:self];
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


- (NSString*) canonicalName {
	[self flush];
	NSMutableArray* modules = [[NSMutableArray alloc] init];
	
	std::vector<std::pair<dgmpp::TypeID, dgmpp::TypeID> > modulePairs;
	std::map<std::pair<dgmpp::TypeID, dgmpp::TypeID>, int> moduleCounts;
	
	for (NSString* key in @[@"hiSlots", @"medSlots", @"lowSlots", @"rigSlots", @"subsystems"]) {
		for (NCLoadoutDataShipModule* item in [self.loadoutData valueForKey:key]) {
			std::pair<dgmpp::TypeID, dgmpp::TypeID> pair(item.typeID, item.chargeID);
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
	for (const auto& pair: modulePairs) {
		NSString* s;
		if (pair.second > 0)
			s = [NSString stringWithFormat:@"%d:%d:%d", pair.first, pair.second, moduleCounts[pair]];
		else
			s = [NSString stringWithFormat:@"%d::%d", pair.first, moduleCounts[pair]];
		[modules addObject:s];
	}
	
	NSMutableArray* drones = [[NSMutableArray alloc] init];
	std::vector<std::pair<dgmpp::TypeID, int> > dronePairs;
	
	for (NCLoadoutDataShipDrone* drone in self.loadoutData.drones) {
		if (!drone.active)
			continue;
		dgmpp::TypeID typeID = drone.typeID;
		int count = drone.count;
		dronePairs.push_back(std::pair<dgmpp::TypeID, int>(typeID, count));
	}
	std::sort(dronePairs.begin(), dronePairs.end());
	
	for (const auto& pair: dronePairs) {
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
	[self flush];
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
	[self flush];
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
	[self flush];
	__block NSString* hyperlinkTag;
	[self.databaseManagedObjectContext performBlockAndWait:^{
		NSString* dna = self.dnaRepresentation;
		NCDBInvType* type = [self.databaseManagedObjectContext invTypeWithTypeID:self.typeID];
		hyperlinkTag = [NSString stringWithFormat:@"<a href=\"javascript:if (typeof CCPEVE != 'undefined') CCPEVE.showFitting('%@'); else window.open('fitting:%@');\">%@ - %@</a>", dna, dna, type.typeName, self.loadoutName];
	}];
	return hyperlinkTag;
}

- (CRFitting*) crFittingRepresentation {
	[self flush];
	CRFitting* fitting = [CRFitting new];
	
	[self.databaseManagedObjectContext performBlockAndWait:^{
		NCDBInvType* type = [self.databaseManagedObjectContext invTypeWithTypeID:self.typeID];
		fitting.ship = [CRFittingType new];
		fitting.ship.typeID = self.typeID;
		fitting.ship.name = type.typeName ?: @"Unknown";
		fitting.name = self.loadoutName ?: fitting.ship.name;
		fitting.fittingDescription = NSLocalizedString(@"Created with Neocom on iOS", nil);
		
		int flags[] = {EVEInventoryFlagLoSlot0, EVEInventoryFlagMedSlot0, EVEInventoryFlagHiSlot0, EVEInventoryFlagRigSlot0, EVEInventoryFlagSubSystem0};
		int n = 0;
		NSMutableArray* items = [NSMutableArray new];
		for (NSString* key in @[@"lowSlots", @"medSlots", @"hiSlots", @"rigSlots", @"subsystems"]) {
			int flag = flags[n++];
			NSArray* array = [self.loadoutData valueForKey:key];
			if (array.count == 0)
				continue;
			for (NCLoadoutDataShipModule* module in array) {
				NCDBInvType* type = [self.databaseManagedObjectContext invTypeWithTypeID:module.typeID];
				CRFittingItem* item = [CRFittingItem new];
				item.quantity = 1;
				item.flag = flag++;
				item.type = [CRFittingType new];
				item.type.typeID = module.typeID;
				item.type.name = type.typeName ?: @"Unknown";
				[items addObject:item];
			}
		}
		for (NCLoadoutDataShipDrone* drone in self.loadoutData.drones) {
			NCDBInvType* type = [self.databaseManagedObjectContext invTypeWithTypeID:drone.typeID];
			CRFittingItem* item = [CRFittingItem new];
			item.quantity = drone.count;
			item.flag = EVEInventoryFlagDroneBay;
			item.type = [CRFittingType new];
			item.type.typeID = drone.typeID;
			item.type.name = type.typeName ?: @"Unknown";
			[items addObject:item];
		}
		fitting.items = items;
	}];

	
	return fitting;
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