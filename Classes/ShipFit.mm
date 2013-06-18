//
//  ShipFit.m
//  EVEUniverse
//
//  Created by Artem Shimanski on 28.01.13.
//
//

#import "ShipFit.h"
#import "EVEDBAPI.h"
#import "EVEOnlineAPI.h"
#import "EVEAssetListItem+AssetsViewController.h"
#import "KillMail.h"
#import "ItemInfo.h"
#import "EUStorage.h"

class ModulesSlotCompare : public std::binary_function<eufe::Module*, eufe::Module*&, bool>
{
public:
	bool operator() (eufe::Module* a, eufe::Module*& b) {
		return a->getSlot() > b->getSlot();
	}
};

@interface ShipFit()
- (NSDictionary*) dictionary;
@end

@implementation ShipFit

@dynamic boosters;
@dynamic drones;
@dynamic implants;
@dynamic hiSlots;
@dynamic medSlots;
@dynamic lowSlots;
@dynamic rigSlots;
@dynamic subsystems;
@dynamic cargo;


@synthesize character = _character;


+ (id) shipFitWithFitName:(NSString*) fitName character:(eufe::Character*) character {
	return [[ShipFit alloc] initWithFitName:fitName character:character];
}

+ (id) shipFitWithBCString:(NSString*) string character:(eufe::Character*) character {
	return [[ShipFit alloc] initWithBCString:string character:character];
}

+ (id) shipFitWithAsset:(EVEAssetListItem*) asset character:(eufe::Character*) character {
	return [[ShipFit alloc] initWithAsset:asset character:character];
	
}

+ (id) shipFitWithKillMail:(KillMail*) killMail character:(eufe::Character*) character {
	return [[ShipFit alloc] initWithKillMail:killMail character:character];
}

+ (id) shipFitWithDNA:(NSString*) dna character:(eufe::Character*) character {
	return [[ShipFit alloc] initWithDNA:dna character:character];
}

+ (NSArray*) allFits {
	EUStorage* storage = [EUStorage sharedStorage];
	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
	[fetchRequest setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"typeName" ascending:YES]]];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"ShipFit" inManagedObjectContext:storage.managedObjectContext];
	[fetchRequest setEntity:entity];
	
	NSError *error = nil;
	NSArray *fetchedObjects = [storage.managedObjectContext executeFetchRequest:fetchRequest error:&error];
	return fetchedObjects;
}

+ (NSString*) allFitsEveXML {
	NSArray* allFits = [self allFits];

	NSMutableString* eveXML = [NSMutableString string];
	[eveXML appendString:@"<?xml version=\"1.0\" ?>\n<fittings>\n"];
	
	for (ShipFit* fit in allFits) {
		[eveXML appendFormat:@"%@\n", [fit fitXML]];
	}
	[eveXML appendString:@"</fittings>"];
	return eveXML;
}

- (id) initWithFitName:(NSString*) aFitName character:(eufe::Character*) aCharacter {
	if (self = [self initWithCharacter:aCharacter]) {
		self.fitName = aFitName;
	}
	return self;
}

- (id) initWithCharacter:(eufe::Character*) aCharacter {
	EUStorage* storage = [EUStorage sharedStorage];
	if (self = [super initWithEntity:[NSEntityDescription entityForName:@"ShipFit" inManagedObjectContext:storage.managedObjectContext] insertIntoManagedObjectContext:nil]) {
		_character = aCharacter;
		if (aCharacter) {
			eufe::Ship* ship = aCharacter->getShip();
			if (ship) {
				ItemInfo* itemInfo = [ItemInfo itemInfoWithItem:ship error:nil];
				self.typeID = itemInfo.typeID;
				self.typeName = itemInfo.typeName;
				self.imageName = itemInfo.typeSmallImageName;
			}
		}
	}
	return self;
}

- (id) initWithBCString:(NSString*) string character:(eufe::Character*) aCharacter {
	if (self = [self initWithCharacter:aCharacter]) {
		if (!aCharacter) {
			return nil;
		}
		
		NSMutableArray *components = [NSMutableArray arrayWithArray:[string componentsSeparatedByString:@":"]];
		[components removeObjectAtIndex:0];
		NSInteger shipID = [[components objectAtIndex:0] integerValue];
		eufe::Ship* ship = aCharacter->setShip(shipID);
		
		if (!ship) {
			return nil;
		}
		else {
			[components removeObjectAtIndex:0];
			NSMutableArray *charges = [NSMutableArray array];
			NSMutableArray *modules = [NSMutableArray array];
			for (NSString *component in components) {
				NSArray *fields = [component componentsSeparatedByString:@"*"];
				if (fields.count == 0)
					continue;
				NSInteger typeID = [[fields objectAtIndex:0] integerValue];
				NSInteger amount = fields.count > 1 ? [[fields objectAtIndex:1] integerValue] : 1;
				EVEDBInvType *type = [EVEDBInvType invTypeWithTypeID:typeID error:nil];
				if (type) {
					if ([type.group.category.categoryName isEqualToString:@"Module"]) {
						for (int i = 0; i < amount; i++)
							[modules addObject:type];
					}
					else if ([type.group.category.categoryName isEqualToString:@"Subsystem"]) {
						for (int i = 0; i < amount; i++)
							ship->addModule(type.typeID);
					}
					else if ([type.group.category.categoryName isEqualToString:@"Charge"]) {
						[charges addObject:type];
					}
					else if ([type.group.category.categoryName isEqualToString:@"Drone"]) {
						for (int i = 0; i < amount; i++)
							ship->addDrone(type.typeID);
					}
				}
			}
			for (EVEDBInvType *type in modules) {
				ship->addModule(type.typeID);
			}
			
			for (EVEDBInvType *type in charges) {
				eufe::Charge* charge (new eufe::Charge(ship->getEngine(), type.typeID, NULL));
				eufe::ModulesList::const_iterator i, end = ship->getModules().end();
				for (i = ship->getModules().begin(); i != end; i++) {
					if ((*i)->canFit(charge))
						(*i)->setCharge(new eufe::Charge(*charge));
				}
				delete charge;
			}
		}
	}
	return self;
}

- (id) initWithAsset:(EVEAssetListItem*) asset character:(eufe::Character*) aCharacter {
	if (self = [self initWithCharacter:aCharacter]) {
		if (!aCharacter) {
			return nil;
		}

		self.fitName = asset.location.itemName ? asset.location.itemName : asset.type.typeName;
		eufe::Ship* ship = aCharacter->setShip(asset.type.typeID);
		
		if (!ship) {
			return nil;
		}
		else {
			NSMutableArray *charges = [NSMutableArray array];
			NSMutableArray *modules = [NSMutableArray array];
			for (EVEAssetListItem* item in asset.contents) {
				int amount = item.quantity;
				if (amount < 1)
					amount = 1;
				EVEDBInvType* type = item.type;
				if ([type.group.category.categoryName isEqualToString:@"Module"]) {
					for (int i = 0; i < amount; i++)
						[modules addObject:type];
				}
				else if ([type.group.category.categoryName isEqualToString:@"Subsystem"]) {
					for (int i = 0; i < amount; i++)
						ship->addModule(type.typeID);
				}
				else if ([type.group.category.categoryName isEqualToString:@"Charge"]) {
					[charges addObject:type];
				}
				else if ([type.group.category.categoryName isEqualToString:@"Drone"]) {
					for (int i = 0; i < amount; i++)
						ship->addDrone(type.typeID);
				}
			}
			for (EVEDBInvType *type in modules) {
				ship->addModule(type.typeID);
			}
			
			for (EVEDBInvType *type in charges) {
				eufe::Charge* charge = new eufe::Charge(ship->getEngine(), type.typeID, NULL);
				eufe::ModulesList::const_iterator i, end = ship->getModules().end();
				for (i = ship->getModules().begin(); i != end; i++) {
					if ((*i)->canFit(charge))
						(*i)->setCharge(new eufe::Charge(*charge));
				}
				delete charge;
			}
		}
	}
	return self;
}

- (id) initWithKillMail:(KillMail*) killMail character:(eufe::Character*) aCharacter {
	if (self = [self initWithCharacter:aCharacter]) {
		if (!aCharacter) {
			return nil;
		}

		self.fitName = killMail.victim.shipType.typeName;
		eufe::Ship* ship = aCharacter->setShip(killMail.victim.shipType.typeID);
		
		if (!ship) {
			return nil;
		}
		else {
			NSMutableArray *charges = [NSMutableArray array];
			NSMutableArray* items = [NSMutableArray arrayWithArray:killMail.subsystemSlots];
			[items addObjectsFromArray:killMail.rigSlots];
			[items addObjectsFromArray:killMail.lowSlots];
			[items addObjectsFromArray:killMail.medSlots];
			[items addObjectsFromArray:killMail.hiSlots];
			
			for (KillMailItem* item in items) {
				int amount = item.qty;
				if (amount < 1)
					amount = 1;
				for (int i = 0; i < amount; i++)
					ship->addModule(item.type.typeID);
			}
			for (KillMailItem* item in killMail.cargo) {
				if ([item.type.group.category.categoryName isEqualToString:@"Charge"]) {
					[charges addObject:item.type];
				}
			}
			for (KillMailItem* item in killMail.droneBay) {
				int amount = item.qty;
				if (amount < 1)
					amount = 1;
				for (int i = 0; i < amount; i++)
					ship->addDrone(item.type.typeID);
			}
			
			for (EVEDBInvType *type in charges) {
				eufe::Charge* charge = new eufe::Charge(ship->getEngine(), type.typeID, NULL);
				eufe::ModulesList::const_iterator i, end = ship->getModules().end();
				for (i = ship->getModules().begin(); i != end; i++) {
					if ((*i)->canFit(charge))
						(*i)->setCharge(new eufe::Charge(*charge));
				}
				delete charge;
			}
		}
	}
	return self;
}

- (id) initWithDNA:(NSString*) dna character:(eufe::Character*) aCharacter {
	if (self = [self initWithCharacter:aCharacter]) {
		if (!aCharacter) {
			return nil;
		}

		NSMutableArray* records = [NSMutableArray arrayWithArray:[dna componentsSeparatedByString:@":"]];
		if (records.count == 0) {
			return nil;
		}
		else {
			NSInteger shipTypeID = [[records objectAtIndex:0] integerValue];
			eufe::Ship* ship = aCharacter->setShip(shipTypeID);
			if (!ship) {
				return nil;
			}
			self.fitName = [NSString stringWithFormat:@"%s", ship->getTypeName()];
			[records removeObjectAtIndex:0];
			
			NSMutableArray* charges = [NSMutableArray array];
			
			for (NSString* record in records) {
				NSArray* components = [record componentsSeparatedByString:@";"];
				NSInteger typeID = 0;
				NSInteger amount = 1;
				
				if (components.count > 0)
					typeID = [[components objectAtIndex:0] integerValue];
				if (components.count > 1)
					amount = [[components objectAtIndex:1] integerValue];
				
				if (amount > 0) {
					EVEDBInvType* type = [EVEDBInvType invTypeWithTypeID:typeID error:nil];
					if (type) {
						if ([type.group.category.categoryName isEqualToString:@"Module"] ||
							[type.group.category.categoryName isEqualToString:@"Subsystem"]) {
							for (NSInteger i = 0; i < amount; i++)
								ship->addModule(typeID);
						}
						else if ([type.group.category.categoryName isEqualToString:@"Charge"]) {
							[charges addObject:type];
						}
						else if ([type.group.category.categoryName isEqualToString:@"Drone"]) {
							for (int i = 0; i < amount; i++)
								ship->addDrone(typeID);
						}
					}
				}
			}
			
			for (EVEDBInvType *type in charges) {
				eufe::Charge* charge = new eufe::Charge(ship->getEngine(), type.typeID, NULL);
				eufe::ModulesList::const_iterator i, end = ship->getModules().end();
				for (i = ship->getModules().begin(); i != end; i++) {
					if ((*i)->canFit(charge))
						(*i)->setCharge(new eufe::Charge(*charge));
				}
				delete charge;
			}
		}
	}
	return self;
}

- (void) save {
	eufe::Character* character = self.character;
	eufe::Ship* ship = character->getShip();
	
	ItemInfo* itemInfo = [ItemInfo itemInfoWithItem:ship error:nil];
	if (self.typeID != itemInfo.typeID) {
		self.typeID = itemInfo.typeID;
		self.imageName = itemInfo.typeSmallImageName;
		self.typeName = itemInfo.typeName;
	}
	
	NSMutableArray* hiSlots = [NSMutableArray array];
	NSMutableArray* medSlots = [NSMutableArray array];
	NSMutableArray* lowSlots = [NSMutableArray array];
	NSMutableArray* rigSlots = [NSMutableArray array];
	NSMutableArray* subsystems = [NSMutableArray array];
	NSMutableDictionary* dronesDic = [NSMutableDictionary dictionary];
	NSMutableArray* drones = [NSMutableArray array];
	NSMutableArray* implants = [NSMutableArray array];
	NSMutableArray* boosters = [NSMutableArray array];
	
	for(auto i : ship->getModules()) {
		eufe::Charge* charge = i->getCharge();
		eufe::TypeID chargeID = charge ? charge->getTypeID() : 0;
		NSString* record = [NSString stringWithFormat:@"%d:1:%d:%d", i->getTypeID(), i->getState(), chargeID];
		
		switch(i->getSlot()) {
			case eufe::Module::SLOT_HI:
				[hiSlots addObject:record];
				break;
			case eufe::Module::SLOT_MED:
				[medSlots addObject:record];
				break;
			case eufe::Module::SLOT_LOW:
				[lowSlots addObject:record];
				break;
			case eufe::Module::SLOT_RIG:
				[rigSlots addObject:record];
				break;
			case eufe::Module::SLOT_SUBSYSTEM:
				[subsystems addObject:record];
				break;
			default:
				break;
		}
	}
	
	for (auto i : ship->getDrones()) {
		NSString* key = [NSString stringWithFormat:@"%d:%d", i->getTypeID(), i->isActive()];
		NSMutableDictionary* dic = [dronesDic valueForKey:key];
		if (!dic) {
			dic = [NSMutableDictionary dictionaryWithObjectsAndKeys:@(i->getTypeID()), @"typeID", @(i->isActive()), @"active", @(dronesDic.count), @"order", @(1), @"count", nil];
			[dronesDic setValue:dic forKey:key];
		}
		else
			[dic setValue:@([[dic valueForKey:@"count"] integerValue] + 1) forKey:@"count"];
	}
	
	for (NSDictionary* dic in [[dronesDic allValues] sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"order" ascending:YES]]]) {
		NSString* record = [NSString stringWithFormat:@"%d:%d:%d", [[dic valueForKey:@"typeID"] integerValue], [[dic valueForKey:@"count"] integerValue], [[dic valueForKey:@"active"] integerValue]];
		[drones addObject:record];
	}
	
	for (auto i : character->getImplants()) {
		NSString* record = [NSString stringWithFormat:@"%d:1", i->getTypeID()];
		[implants addObject:record];
	}
	
	for (auto i : character->getBoosters()) {
		NSString* record = [NSString stringWithFormat:@"%d:1", i->getTypeID()];
		[boosters addObject:record];
	}
	
	NSString* hiSlotsString = [hiSlots componentsJoinedByString:@";"];
	NSString* medSlotsString = [medSlots componentsJoinedByString:@";"];
	NSString* lowSlotsString = [lowSlots componentsJoinedByString:@";"];
	NSString* rigSlotsString = [rigSlots componentsJoinedByString:@";"];
	NSString* subsystemsString = [subsystems componentsJoinedByString:@";"];
	NSString* dronesString = [drones componentsJoinedByString:@";"];
	NSString* implantsString = [implants componentsJoinedByString:@";"];
	NSString* boostersString = [boosters componentsJoinedByString:@";"];

	if (![self.hiSlots isEqualToString:hiSlotsString])
		self.hiSlots = hiSlotsString;
	
	if (![self.medSlots isEqualToString:medSlotsString])
		self.medSlots = medSlotsString;
	
	if (![self.lowSlots isEqualToString:lowSlotsString])
		self.lowSlots = lowSlotsString;
	
	if (![self.rigSlots isEqualToString:rigSlotsString])
		self.rigSlots = rigSlotsString;

	if (![self.subsystems isEqualToString:subsystemsString])
		self.subsystems = subsystemsString;

	
	if (![self.drones isEqualToString:dronesString])
		self.drones = dronesString;
	
	if (![self.implants isEqualToString:implantsString])
		self.implants = implantsString;

	if (![self.boosters isEqualToString:boostersString])
		self.boosters = boostersString;
	
	EUStorage* storage = [EUStorage sharedStorage];
	
	if (![self managedObjectContext])
		[storage.managedObjectContext insertObject:self];
	[storage saveContext];
}

- (void) load {
	NSDictionary* dictionary = [self dictionary];
	[self.managedObjectContext performBlockAndWait:^{
		eufe::Character* character = self.character;
		if (character) {
			if (self.typeID) {
				eufe::Ship* ship = character->setShip(self.typeID);
				if (ship) {
					for (NSString* key in @[@"subsystems", @"rigSlots", @"lowSlots", @"medSlots", @"hiSlots"]) {
						for (NSDictionary* record in [dictionary valueForKey:key]) {
							NSInteger typeID = [[record valueForKey:@"typeID"] integerValue];
							NSInteger count = [[record valueForKey:@"count"] integerValue];
							eufe::Module::State state = (eufe::Module::State) [[record valueForKey:@"state"] integerValue];
							NSInteger chargeTypeID = [[record valueForKey:@"chargeTypeID"] integerValue];
							
							for (NSInteger i = 0; i < count; i++) {
								eufe::Module* module = ship->addModule(typeID);
								if (!module)
									break;
								module->setState(state);
								if (chargeTypeID)
									module->setCharge(chargeTypeID);
							}
						}
					}
					
					for (NSDictionary* record in [dictionary valueForKey:@"drones"]) {
						NSInteger typeID = [[record valueForKey:@"typeID"] integerValue];
						NSInteger count = [[record valueForKey:@"count"] integerValue];
						bool active = [[record valueForKey:@"active"] boolValue];
						
						for (NSInteger i = 0; i < count; i++) {
							eufe::Drone* drone = ship->addDrone(typeID);
							if (!drone)
								break;
							drone->setActive(active);
						}
					}
				}
				
				for (NSDictionary* record in [dictionary valueForKey:@"implants"]) {
					NSInteger typeID = [[record valueForKey:@"typeID"] integerValue];
					NSInteger count = [[record valueForKey:@"count"] integerValue];
					
					for (NSInteger i = 0; i < count; i++) {
						if (!character->addImplant(typeID))
							break;
					}
				}

				for (NSDictionary* record in [dictionary valueForKey:@"boosters"]) {
					NSInteger typeID = [[record valueForKey:@"typeID"] integerValue];
					NSInteger count = [[record valueForKey:@"count"] integerValue];
					
					for (NSInteger i = 0; i < count; i++) {
						if (!character->addBooster(typeID))
							break;
					}
				}

				for (NSString* row in [self.boosters componentsSeparatedByString:@";"]) {
					NSArray* components = [row componentsSeparatedByString:@":"];
					NSInteger numberOfComponents = components.count;
					
					if (numberOfComponents >= 1) {
						eufe::TypeID typeID = [[components objectAtIndex:0] integerValue];
						if (typeID) {
							NSInteger boostersCount = numberOfComponents >= 2 ? [[components objectAtIndex:1] integerValue] : 1;
							
							for (NSInteger i = 0; i < boostersCount; i++) {
								if (!character->addBooster(typeID))
									break;
							}
						}
					}
				}
				
			}
		}
	}];
}

- (void) unload {
	self.character = NULL;
}

- (NSString*) dna {
	NSMutableString* dna = [NSMutableString string];
	NSCountedSet* subsystems = [NSCountedSet set];
	NSCountedSet* highs = [NSCountedSet set];
	NSCountedSet* meds = [NSCountedSet set];
	NSCountedSet* lows = [NSCountedSet set];
	NSCountedSet* rigs = [NSCountedSet set];
	NSCountedSet* drones = [NSCountedSet set];
	NSCountedSet* charges = [NSCountedSet set];

	eufe::Character* character = self.character;
	
	if (character) {
		eufe::Ship* ship = character->getShip();
		
		const eufe::ModulesList& modulesList = ship->getModules();
		eufe::ModulesList::const_iterator i, end = modulesList.end();
		for(i = modulesList.begin(); i != end; i++) {
			ItemInfo* itemInfo = [ItemInfo itemInfoWithItem:dynamic_cast<eufe::Item*>(*i) error:nil];
			switch((*i)->getSlot()) {
				case eufe::Module::SLOT_SUBSYSTEM:
					[subsystems addObject:itemInfo];
					break;
				case eufe::Module::SLOT_HI:
					[highs addObject:itemInfo];
					break;
				case eufe::Module::SLOT_MED:
					[meds addObject:itemInfo];
					break;
				case eufe::Module::SLOT_LOW:
					[lows addObject:itemInfo];
					break;
				case eufe::Module::SLOT_RIG:
					[rigs addObject:itemInfo];
					break;
				default:
					break;
			}
			
			eufe::Charge* charge = (*i)->getCharge();
			if (charge) {
				itemInfo = [ItemInfo itemInfoWithItem:dynamic_cast<eufe::Item*>(charge) error:nil];
				if (![charges containsObject:itemInfo])
					[charges addObject:itemInfo];
			}
		}
		
		const eufe::DronesList& dronesList = ship->getDrones();
		eufe::DronesList::const_iterator j, endj = dronesList.end();
		for(j = dronesList.begin(); j != endj; j++) {
			ItemInfo* itemInfo = [ItemInfo itemInfoWithItem:dynamic_cast<eufe::Item*>(*j) error:nil];
			[drones addObject:itemInfo];
		}
		
		[dna appendFormat:@"%d:", ship->getTypeID()];
		
		NSCountedSet* slots[] = {subsystems, highs, meds, lows, rigs, drones, charges};
		for (int i = 0; i < 7; i++) {
			for (ItemInfo* itemInfo in slots[i]) {
				[dna appendFormat:@"%d;%d:", itemInfo.typeID, [slots[i] countForObject:itemInfo]];
			}
		}
		[dna appendString:@":"];
	}
	else {
		NSDictionary* dictionary = self.dictionary;
		NSString* keys[] = {@"subsystems", @"hiSlots", @"medSlots", @"lowSlots", @"rigSlots"};
		NSCountedSet* sets[] = {subsystems, highs, meds, lows, rigs};
		NSInteger n = 5;
		
		for (NSInteger i = 0; i < n; i++) {
			NSString* key = keys[i];
			NSCountedSet* set = sets[i];
			
			for (NSDictionary* module in [dictionary valueForKey:key]) {
				NSNumber* typeID = [module valueForKey:@"typeID"];
				NSInteger count = [[module valueForKey:@"count"] integerValue];
				NSNumber* chargeTypeID = [module valueForKey:@"chargeTypeID"];
				for (NSInteger i = 0; i < count; i++)
					[set addObject:typeID];
				if (chargeTypeID)
					[charges addObject:chargeTypeID];
			}
		}
		
		for (NSDictionary* drone in [dictionary valueForKey:@"drones"]) {
			NSNumber* typeID = [drone valueForKey:@"typeID"];
			NSInteger count = [[drone valueForKey:@"count"] integerValue];
			for (NSInteger i = 0; i < count; i++)
				[drones addObject:typeID];
		}
		
		[dna appendFormat:@"%d:", self.typeID];

		NSCountedSet* slots[] = {subsystems, highs, meds, lows, rigs, drones, charges};
		for (int i = 0; i < 7; i++) {
			for (NSNumber* typeID in slots[i]) {
				[dna appendFormat:@"%@;%d:", typeID, [slots[i] countForObject:typeID]];
			}
		}
		[dna appendString:@":"];
	}
	return dna;
}

- (NSString*) eveXML {
	NSMutableString* xml = [NSMutableString string];
	[xml appendString:@"<?xml version=\"1.0\" ?>\n<fittings>\n"];
	[xml appendString:[self fitXML]];
	[xml appendString:@"</fittings>"];
	return xml;
}

- (NSString*) fitXML {
	NSMutableString* xml = [NSMutableString string];
	eufe::Character* aCharacter = self.character;
	if (aCharacter) {
		eufe::Ship* ship = aCharacter->getShip();
		
		[xml appendFormat:@"<fitting name=\"%@\">\n<description value=\"EVEUniverse fitting engine\"/>\n<shipType value=\"%s\"/>\n", self.fitName, ship->getTypeName()];
		
		eufe::ModulesList modulesList = ship->getModules();
		modulesList.sort(ModulesSlotCompare());
		int counters[eufe::Module::SLOT_SUBSYSTEM + 1] = {0};
		const char* slots[] = {"none", "hi slot", "med slot", "low slot", "rig slot", "subsystem slot"};
		eufe::ModulesList::const_iterator i, end = modulesList.end();
		
		for(i = modulesList.begin(); i != end; i++) {
			eufe::Module::Slot slot = (*i)->getSlot();
			[xml appendFormat:@"<hardware slot=\"%s %d\" type=\"%s\"/>\n", slots[slot], counters[slot]++, (*i)->getTypeName()];
		}
		
		NSCountedSet* drones = [NSCountedSet set];
		const eufe::DronesList& dronesList = ship->getDrones();
		eufe::DronesList::const_iterator j, endj = dronesList.end();
		for(j = dronesList.begin(); j != endj; j++) {
			ItemInfo* itemInfo = [ItemInfo itemInfoWithItem:dynamic_cast<eufe::Item*>(*j) error:nil];
			[drones addObject:itemInfo];
		}
		
		for (ItemInfo* itemInfo in drones) {
			[xml appendFormat:@"<hardware slot=\"drone bay\" qty=\"%d\" type=\"%@\"/>\n", [drones countForObject:itemInfo], itemInfo.typeName];
		}
		[xml appendString:@"</fitting>\n"];
	}
	else {
		[xml appendFormat:@"<fitting name=\"%@\">\n<description value=\"EVEUniverse fitting engine\"/>\n<shipType value=\"%@\"/>\n", self.fitName, self.typeName];

		NSDictionary* dictionary = self.dictionary;
		NSArray* keys = @[@"hiSlots", @"medSlots", @"lowSlots", @"rigSlots", @"subsystems"];
		NSArray* slots = @[@"hi slot", @"med slot", @"low slot", @"rig slot", @"subsystem slot"];
		NSInteger n = keys.count;
		
		for (NSInteger i = 0; i < n; i++) {
			NSString* key = [keys objectAtIndex:i];
			NSString* slot = [slots objectAtIndex:i];
			NSInteger count = 0;
			for (NSDictionary* module in [dictionary valueForKey:key]) {
				NSInteger typeID = [[module valueForKey:@"typeID"] integerValue];
				NSInteger modulesCount = [[module valueForKey:@"count"] integerValue];
				EVEDBInvType* type = [EVEDBInvType invTypeWithTypeID:typeID error:nil];
				NSString* typeName = type.typeName;
				for (NSInteger j = 0; j < modulesCount; j++)
					[xml appendFormat:@"<hardware slot=\"%@ %d\" type=\"%@\"/>\n", slot, count++, typeName];
			}
		}
		
		for (NSDictionary* drone in [dictionary valueForKey:@"drones"]) {
			NSInteger typeID = [[drone valueForKey:@"typeID"] integerValue];
			NSInteger count = [[drone valueForKey:@"count"] integerValue];
			EVEDBInvType* type = [EVEDBInvType invTypeWithTypeID:typeID error:nil];
			[xml appendFormat:@"<hardware slot=\"drone bay\" qty=\"%d\" type=\"%@\"/>\n", count, type.typeName];
		}
		[xml appendString:@"</fitting>\n"];
	}
	return xml;
}

#pragma mark - Private

- (NSDictionary*) dictionary {
	NSMutableDictionary* dictionary = [NSMutableDictionary dictionary];
	[self.managedObjectContext performBlockAndWait:^{
		NSMutableArray* hiSlots = [NSMutableArray array];
		NSMutableArray* medSlots = [NSMutableArray array];
		NSMutableArray* lowSlots = [NSMutableArray array];
		NSMutableArray* rigSlots = [NSMutableArray array];
		NSMutableArray* subsystems = [NSMutableArray array];
		NSMutableArray* drones = [NSMutableArray array];
		NSMutableArray* implants = [NSMutableArray array];
		NSMutableArray* boosters = [NSMutableArray array];
		
		NSArray* slotStrings = @[self.hiSlots, self.medSlots, self.lowSlots, self.rigSlots, self.subsystems];
		NSArray* arrays = @[hiSlots, medSlots, lowSlots, rigSlots, subsystems];
		NSInteger n = slotStrings.count;
		
		for (NSInteger i = 0; i < n; i++) {
			NSString* slotString = [slotStrings objectAtIndex:i];
			NSMutableArray* array = [arrays objectAtIndex:i];

			for (NSString* row in [slotString componentsSeparatedByString:@";"]) {
				NSArray* components = [row componentsSeparatedByString:@":"];
				NSInteger numberOfComponents = components.count;
				
				if (numberOfComponents >= 1) {
					eufe::TypeID typeID = [[components objectAtIndex:0] integerValue];
					if (typeID) {
						NSInteger modulesCount = numberOfComponents >= 2 ? [[components objectAtIndex:1] integerValue] : 1;
						eufe::Module::State state = numberOfComponents >= 3 ? (eufe::Module::State) [[components objectAtIndex:2] integerValue] : eufe::Module::STATE_ONLINE;
						NSInteger chargeTypeID = numberOfComponents >= 4 ? [[components objectAtIndex:3] integerValue] : 0;
						
						NSMutableDictionary* module = [NSMutableDictionary dictionary];
						[module setValue:@(typeID) forKey:@"typeID"];
						[module setValue:@(modulesCount) forKey:@"count"];
						[module setValue:@(state) forKey:@"state"];
						if (chargeTypeID)
							[module setValue:@(chargeTypeID) forKey:@"chargeTypeID"];
						[array addObject:module];
					}
				}
			}
		}
		
		
		for (NSString* row in [self.drones componentsSeparatedByString:@";"]) {
			NSArray* components = [row componentsSeparatedByString:@":"];
			NSInteger numberOfComponents = components.count;
			
			if (numberOfComponents >= 1) {
				eufe::TypeID typeID = [[components objectAtIndex:0] integerValue];
				if (typeID) {
					NSInteger dronesCount = numberOfComponents >= 2 ? [[components objectAtIndex:1] integerValue] : 1;
					bool active = numberOfComponents >= 3 ? [[components objectAtIndex:2] boolValue] : true;
					
					NSDictionary* drone = @{@"typeID" : @(typeID), @"count" : @(dronesCount), @"active" : @(active)};
					[drones addObject:drone];
				}
			}
		}
		
		for (NSString* row in [self.implants componentsSeparatedByString:@";"]) {
			NSArray* components = [row componentsSeparatedByString:@":"];
			NSInteger numberOfComponents = components.count;
			
			if (numberOfComponents >= 1) {
				eufe::TypeID typeID = [[components objectAtIndex:0] integerValue];
				if (typeID) {
					NSInteger implantsCount = numberOfComponents >= 2 ? [[components objectAtIndex:1] integerValue] : 1;
					NSDictionary* implant = @{@"typeID" : @(typeID), @"count" : @(implantsCount)};
					[implants addObject:implant];
				}
			}
		}
		
		for (NSString* row in [self.boosters componentsSeparatedByString:@";"]) {
			NSArray* components = [row componentsSeparatedByString:@":"];
			NSInteger numberOfComponents = components.count;
			
			if (numberOfComponents >= 1) {
				eufe::TypeID typeID = [[components objectAtIndex:0] integerValue];
				if (typeID) {
					NSInteger boostersCount = numberOfComponents >= 2 ? [[components objectAtIndex:1] integerValue] : 1;
					NSDictionary* booster = @{@"typeID" : @(typeID), @"count" : @(boostersCount)};
					[boosters addObject:booster];
				}
			}
		}
		
		[dictionary setValue:hiSlots forKey:@"hiSlots"];
		[dictionary setValue:medSlots forKey:@"medSlots"];
		[dictionary setValue:lowSlots forKey:@"lowSlots"];
		[dictionary setValue:rigSlots forKey:@"rigSlots"];
		[dictionary setValue:subsystems forKey:@"subsystems"];
		[dictionary setValue:drones forKey:@"drones"];
		[dictionary setValue:implants forKey:@"implants"];
		[dictionary setValue:boosters forKey:@"boosters"];
	}];
	return dictionary;
}

@end
