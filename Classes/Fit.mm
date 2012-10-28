//
//  Fit.m
//  EVEUniverse
//
//  Created by Mr. Depth on 12/20/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "Fit.h"
#import "ItemInfo.h"
#import "Globals.h"
#import "EVEDBAPI.h"
#import "EVEOnlineAPI.h"
#import "EVEAssetListItem+AssetsViewController.h"
#import "NSString+UUID.h"

#include <functional>

@interface Fit(Private)

- (void) clear;

@end

class FitContext : public eufe::Item::Context
{
public:
	FitContext(Fit* fit) : fit_([fit retain]) {}
	
	virtual ~FitContext()
	{
		[fit_ clear];
		[fit_ release];
	}
	
	Fit* getFit() const {return fit_;}
private:
	Fit* fit_;
};

class SubsystemsFirstCompare : public std::binary_function<eufe::Module*, eufe::Module*, bool>
{
public:
	bool operator() (eufe::Module* a, eufe::Module* b) {
		eufe::Module::Slot slotA = a->getSlot();
		if (slotA == eufe::Module::SLOT_SUBSYSTEM)
			return true;
		else
			return false;
	}
};

class ModulesSlotCompare : public std::binary_function<eufe::Module*, eufe::Module*&, bool>
{
public:
	bool operator() (eufe::Module* a, eufe::Module*& b) {
		return a->getSlot() > b->getSlot();
	}
};

@implementation Fit
@synthesize fitID;
@synthesize fitName;
@synthesize fitURL;
@synthesize character;

+ (id) fitWithFitID:(NSString*) fitID fitName:(NSString*) fitName character:(eufe::Character*) character {
	return [[[Fit alloc] initWithFitID:fitID fitName:fitName character:character] autorelease];
}

+ (id) fitWithDictionary:(NSDictionary*) dictionary character:(eufe::Character*) character {
	return [[[Fit alloc] initWithDictionary:dictionary character:character] autorelease];
}

+ (id) fitWithCharacter:(eufe::Character*) character error:(NSError **)errorPtr {
	const eufe::Item::Context* context = character->getContext();
	if (context == NULL)
	{
		Fit* fit = [[[Fit alloc] initWithCharacter:character error:errorPtr] autorelease];
		FitContext* context = new FitContext(fit);
		character->setContext(context);
		return fit;
	}
	else
		return dynamic_cast<const FitContext*>(context)->getFit();
}

+ (id) fitWithBCString:(NSString*) string character:(eufe::Character*) character {
	return [[[Fit alloc] initWithBCString:string character:character] autorelease];
}

+ (id) fitWithAsset:(EVEAssetListItem*) asset character:(eufe::Character*) character {
	return [[[Fit alloc] initWithAsset:asset character:character] autorelease];
	
}

- (id) initWithFitID:(NSString*) aFitID fitName:(NSString*) aFitName character:(eufe::Character*) aCharacter {
	if (self = [super init]) {
		self.fitID = aFitID;
		self.fitName = aFitName;
		character = aCharacter;
	}
	return self;
}

- (id) initWithDictionary:(NSDictionary*) dictionary character:(eufe::Character*) aCharacter {
	NSString* aFitID = [dictionary valueForKey:@"fitID"];
	NSString *aFitName = [dictionary valueForKey:@"fitName"];
	if (self = [self initWithFitID:aFitID fitName:aFitName character:aCharacter]) {
		NSDictionary* fit = [dictionary valueForKey:@"fit"];
		NSInteger shipID = [[fit valueForKey:@"shipID"] integerValue];
		eufe::Ship* ship = aCharacter->setShip(shipID);
		if (!ship) {
			[self release];
			return nil;
		}
		
		NSMutableArray *modules = [NSMutableArray array];
		for (NSDictionary* record in [fit valueForKey:@"modules"]) {
			NSInteger typeID = [[record valueForKey:@"typeID"] integerValue];
			EVEDBInvType *type = [EVEDBInvType invTypeWithTypeID:typeID error:nil];
			if ([type.group.category.categoryName isEqualToString:@"Subsystem"])
				[modules insertObject:record atIndex:0];
			else
				[modules addObject:record];
		}
		
		NSMutableArray* arrays[] = {[fit valueForKey:@"subsystems"], [fit valueForKey:@"rigs"], [fit valueForKey:@"lows"], [fit valueForKey:@"meds"], [fit valueForKey:@"highs"]};
		for (int i = 0; i < 5; i++) {
			if (arrays[i])
				[modules addObjectsFromArray:arrays[i]];
		}
		
		std::list<boost::tuple<eufe::Module*, eufe::Module::State> > states;

		for (NSDictionary* record in modules) {
			NSInteger typeID = [[record valueForKey:@"typeID"] integerValue];
			NSInteger chargeID = [[record valueForKey:@"chargeID"] integerValue];
			if (typeID != 0) {
				eufe::Module::State state = static_cast<eufe::Module::State>([[record valueForKey:@"state"] integerValue]);
				eufe::Module* module = ship->addModule(typeID);
				if (module != NULL) {
					if (chargeID != 0)
						module->setCharge(chargeID);
					if (module->canHaveState(state))
						module->setState(state);
					else
						states.push_back(boost::tuple<eufe::Module*, eufe::Module::State>(module, state));
				}
			}
		}
		
		std::list<boost::tuple<eufe::Module*, eufe::Module::State> >::iterator i, end = states.end();
		for (i = states.begin(); i != end; i++)
			i->get<0>()->setState(i->get<1>());

		for (NSDictionary* record in [fit valueForKey:@"drones"]) {
			NSInteger typeID = [[record valueForKey:@"typeID"] integerValue];
			if (typeID != 0) {
				eufe::Drone* drone = ship->addDrone(typeID);
				if (drone != NULL && [record valueForKey:@"active"] != nil) {
					BOOL active = [[record valueForKey:@"active"] boolValue];
					drone->setActive(active);
				}
			}
		}
		
		for (NSDictionary *record in [fit valueForKey:@"implants"]) {
			NSInteger typeID = [[record valueForKey:@"typeID"] integerValue];
			if (typeID != 0)
				aCharacter->addImplant(typeID);
		}

		for (NSDictionary *record in [fit valueForKey:@"boosters"]) {
			NSInteger typeID = [[record valueForKey:@"typeID"] integerValue];
			if (typeID != 0)
				aCharacter->addBooster(typeID);
		}
	}
	return self;
}

- (id) initWithCharacter:(eufe::Character*) aCharacter error:(NSError **)errorPtr {
	if (self = [super init]) {
		character = aCharacter;
	}
	return self;
}

- (id) initWithBCString:(NSString*) string character:(eufe::Character*) aCharacter {
	if (self = [self initWithCharacter:aCharacter error:nil]) {
		NSMutableArray *components = [NSMutableArray arrayWithArray:[string componentsSeparatedByString:@":"]];
		[components removeObjectAtIndex:0];
		NSInteger shipID = [[components objectAtIndex:0] integerValue];
		eufe::Ship* ship = aCharacter->setShip(shipID);
		
		if (!ship) {
			[self release];
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
							//ship->addModule(type.typeID);
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
	if (self = [self initWithCharacter:aCharacter error:nil]) {
		self.fitName = asset.location.itemName ? asset.location.itemName : asset.type.typeName;
		eufe::Ship* ship = aCharacter->setShip(asset.type.typeID);
		
		if (!ship) {
			[self release];
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
	

- (void) dealloc {
	[fitName release];
	[fitURL release];
	[fitID release];
	[super dealloc];
}


- (NSDictionary*) dictionary {
	eufe::Character* aCharacter = self.character;
	eufe::Ship* ship = aCharacter->getShip();
	ItemInfo* itemInfo = [ItemInfo itemInfoWithItem:ship error:NULL];
	if (ship == NULL)
		return nil;

	//NSMutableArray* modules = [NSMutableArray array];
	NSMutableArray* slots[eufe::Module::SLOT_SUBSYSTEM + 1] = {nil, [NSMutableArray array], [NSMutableArray array], [NSMutableArray array], [NSMutableArray array], [NSMutableArray array]}; 
	{
		eufe::ModulesList modulesList = ship->getModules();
		modulesList.sort(SubsystemsFirstCompare());
		eufe::ModulesList::const_iterator i, end = modulesList.end();
		for(i = modulesList.begin(); i != end; i++) {
			NSMutableDictionary* row = [NSMutableDictionary dictionaryWithObjectsAndKeys:
										[NSNumber numberWithInteger:(*i)->getTypeID()], @"typeID",
										[NSNumber numberWithInteger:(*i)->getState()], @"state", nil];
			if ((*i)->getCharge() != NULL)
				[row setValue:[NSNumber numberWithInteger:(*i)->getCharge()->getTypeID()] forKey:@"chargeID"];
			//[modules addObject:row];
			[slots[(*i)->getSlot()] addObject:row];
		}
	}
	
	NSMutableArray* drones = [NSMutableArray array];
	{
		const eufe::DronesList& dronesList = ship->getDrones();
		eufe::DronesList::const_iterator i, end = dronesList.end();
		for(i = dronesList.begin(); i != end; i++) {
			NSMutableDictionary* row = [NSDictionary dictionaryWithObjectsAndKeys:
										[NSNumber numberWithInteger:(*i)->getTypeID()], @"typeID",
										[NSNumber numberWithBool:(*i)->isActive()], @"active",
										nil];
			[drones addObject:row];
		}
	}
	
	NSMutableArray* implants = [NSMutableArray array];
	{
		const eufe::ImplantsList& implantsList = aCharacter->getImplants();
		eufe::ImplantsList::const_iterator i, end = implantsList.end();
		for(i = implantsList.begin(); i != end; i++) {
			NSMutableDictionary* row = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInteger:(*i)->getTypeID()], @"typeID", nil];
			[implants addObject:row];
		}
	}

	NSMutableArray* boosters = [NSMutableArray array];
	{
		const eufe::BoostersList& boostersList = aCharacter->getBoosters();
		eufe::BoostersList::const_iterator i, end = boostersList.end();
		for(i = boostersList.begin(); i != end; i++) {
			NSMutableDictionary* row = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInteger:(*i)->getTypeID()], @"typeID", nil];
			[boosters addObject:row];
		}
	}

	NSDictionary* fit = [NSDictionary dictionaryWithObjectsAndKeys:
						 [NSNumber numberWithInteger:ship->getTypeID()], @"shipID",
						 slots[eufe::Module::SLOT_HI], @"highs",
						 slots[eufe::Module::SLOT_MED], @"meds",
						 slots[eufe::Module::SLOT_LOW], @"lows",
						 slots[eufe::Module::SLOT_RIG], @"rigs",
						 slots[eufe::Module::SLOT_SUBSYSTEM], @"subsystems",
						 drones, @"drones",
						 implants, @"implants",
						 boosters, @"boosters",nil];
	if (!fitID)
		self.fitID = [NSString uuidString];
	return [NSDictionary dictionaryWithObjectsAndKeys:
			fitID, @"fitID",
			fitName, @"fitName",
			itemInfo.typeName, @"shipName",
			[itemInfo typeSmallImageName], @"imageName",
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
	for (NSDictionary *item in fits) {
		if ([[item valueForKey:@"fitID"] isEqualToString:fitID]) {
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

- (NSString*) dna {
	NSMutableString* dna = [NSMutableString string];
	eufe::Character* aCharacter = self.character;
	eufe::Ship* ship = aCharacter->getShip();
	NSCountedSet* subsystems = [NSCountedSet set];
	NSCountedSet* highs = [NSCountedSet set];
	NSCountedSet* meds = [NSCountedSet set];
	NSCountedSet* lows = [NSCountedSet set];
	NSCountedSet* rigs = [NSCountedSet set];
	NSCountedSet* drones = [NSCountedSet set];
	NSCountedSet* charges = [NSCountedSet set];

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
	return dna;
}

- (NSString*) eveXML {
	NSMutableString* xml = [NSMutableString string];
	eufe::Character* aCharacter = self.character;
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
	return xml;
}

@end

@implementation Fit(Private)

- (void) clear {
	character = NULL;
}

@end