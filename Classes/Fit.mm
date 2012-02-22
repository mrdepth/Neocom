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
	
	Fit* getFit() {return fit_;}
private:
	Fit* fit_;
};

class SubsystemsFirstCompare : public std::binary_function<const boost::shared_ptr<eufe::Module>&, const boost::shared_ptr<eufe::Module>&, bool>
{
public:
	bool operator() (const boost::shared_ptr<eufe::Module>& a, const boost::shared_ptr<eufe::Module>& b) {
		eufe::Module::Slot slotA = a->getSlot();
		if (slotA == eufe::Module::SLOT_SUBSYSTEM)
			return true;
		else
			return false;
	}
};

@implementation Fit
@synthesize fitID;
@synthesize fitName;
@synthesize fitURL;

+ (id) fitWithFitID:(NSInteger) fitID fitName:(NSString*) fitName character:(boost::shared_ptr<eufe::Character>) character {
	return [[[Fit alloc] initWithFitID:fitID fitName:fitName character:character] autorelease];
}

+ (id) fitWithDictionary:(NSDictionary*) dictionary character:(boost::shared_ptr<eufe::Character>) character {
	return [[[Fit alloc] initWithDictionary:dictionary character:character] autorelease];
}

+ (id) fitWithCharacter:(boost::shared_ptr<eufe::Character>) character error:(NSError **)errorPtr {
	boost::shared_ptr<eufe::Item::Context> context = character->getContext();
	if (context == NULL)
	{
		Fit* fit = [[[Fit alloc] initWithCharacter:character error:errorPtr] autorelease];
		FitContext* context = new FitContext(fit);
		character->setContext(boost::shared_ptr<eufe::Item::Context>(context));
		return fit;
	}
	else
		return dynamic_cast<FitContext*>(context.get())->getFit();
}

+ (id) fitWithBCString:(NSString*) string character:(boost::shared_ptr<eufe::Character>) character {
	return [[[Fit alloc] initWithBCString:string character:character] autorelease];
}

+ (id) fitWithAsset:(EVEAssetListItem*) asset character:(boost::shared_ptr<eufe::Character>) character {
	return [[[Fit alloc] initWithAsset:asset character:character] autorelease];
	
}

- (id) initWithFitID:(NSInteger) aFitID fitName:(NSString*) aFitName character:(boost::shared_ptr<eufe::Character>) aCharacter {
	if (self = [super init]) {
		fitID = aFitID;
		self.fitName = aFitName;
		character = boost::weak_ptr<eufe::Character>(aCharacter);
	}
	return self;
}

- (id) initWithDictionary:(NSDictionary*) dictionary character:(boost::shared_ptr<eufe::Character>) aCharacter {
	NSInteger aFitID = [[dictionary valueForKey:@"fitID"] integerValue];
	NSString *aFitName = [dictionary valueForKey:@"fitName"];
	if (self = [self initWithFitID:aFitID fitName:aFitName character:aCharacter]) {
		NSDictionary* fit = [dictionary valueForKey:@"fit"];
		NSInteger shipID = [[fit valueForKey:@"shipID"] integerValue];
		eufe::Ship* ship = aCharacter->setShip(shipID).get();
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
		
		std::list<boost::tuple<boost::shared_ptr<eufe::Module>, eufe::Module::State> > states;

		for (NSDictionary* record in modules) {
			NSInteger typeID = [[record valueForKey:@"typeID"] integerValue];
			NSInteger chargeID = [[record valueForKey:@"chargeID"] integerValue];
			if (typeID != 0) {
				eufe::Module::State state = static_cast<eufe::Module::State>([[record valueForKey:@"state"] integerValue]);
				boost::shared_ptr<eufe::Module> module = ship->addModule(typeID);
				if (module != NULL) {
					if (chargeID != 0)
						module->setCharge(chargeID);
					if (module->canHaveState(state))
						module->setState(state);
					else
						states.push_back(boost::tuple<boost::shared_ptr<eufe::Module>, eufe::Module::State>(module, state));
				}
			}
		}
		
		std::list<boost::tuple<boost::shared_ptr<eufe::Module>, eufe::Module::State> >::iterator i, end = states.end();
		for (i = states.begin(); i != end; i++)
			i->get<0>()->setState(i->get<1>());

		for (NSDictionary* record in [fit valueForKey:@"drones"]) {
			NSInteger typeID = [[record valueForKey:@"typeID"] integerValue];
			if (typeID != 0) {
				boost::shared_ptr<eufe::Drone> drone = ship->addDrone(typeID);
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

- (id) initWithCharacter:(boost::shared_ptr<eufe::Character>) aCharacter error:(NSError **)errorPtr {
	if (self = [super init]) {
		character = boost::weak_ptr<eufe::Character>(aCharacter);
	}
	return self;
}

- (id) initWithBCString:(NSString*) string character:(boost::shared_ptr<eufe::Character>) aCharacter {
	if (self = [self initWithCharacter:aCharacter error:nil]) {
		NSMutableArray *components = [NSMutableArray arrayWithArray:[string componentsSeparatedByString:@":"]];
		[components removeObjectAtIndex:0];
		NSInteger shipID = [[components objectAtIndex:0] integerValue];
		eufe::Ship* ship = aCharacter->setShip(shipID).get();
		
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
				boost::shared_ptr<eufe::Charge> charge (new eufe::Charge(ship->getEngine(), type.typeID, NULL));
				eufe::ModulesList::const_iterator i, end = ship->getModules().end();
				for (i = ship->getModules().begin(); i != end; i++) {
					if ((*i)->canFit(charge))
						(*i)->setCharge(boost::shared_ptr<eufe::Charge>(new eufe::Charge(*charge)));
				}
			}
		}
	}
	return self;
}

- (id) initWithAsset:(EVEAssetListItem*) asset character:(boost::shared_ptr<eufe::Character>) aCharacter {
	if (self = [self initWithCharacter:aCharacter error:nil]) {
		self.fitName = asset.location.itemName ? asset.location.itemName : asset.type.typeName;
		eufe::Ship* ship = aCharacter->setShip(asset.type.typeID).get();
		
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
				boost::shared_ptr<eufe::Charge> charge (new eufe::Charge(ship->getEngine(), type.typeID, NULL));
				eufe::ModulesList::const_iterator i, end = ship->getModules().end();
				for (i = ship->getModules().begin(); i != end; i++) {
					if ((*i)->canFit(charge))
						(*i)->setCharge(boost::shared_ptr<eufe::Charge>(new eufe::Charge(*charge)));
				}
			}
		}
	}
	return self;
}
	

- (void) dealloc {
	[fitName release];
	[fitURL release];
	[super dealloc];
}


- (boost::shared_ptr<eufe::Character>) character {
	return character.lock();
}

- (NSDictionary*) dictionary {
	boost::shared_ptr<eufe::Character> aCharacter = self.character;
	boost::shared_ptr<eufe::Ship> ship = aCharacter->getShip();
	ItemInfo* itemInfo = [ItemInfo itemInfoWithItem:ship error:NULL];
	if (ship == NULL)
		return nil;

	NSMutableArray* modules = [NSMutableArray array];
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
			[modules addObject:row];
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
						 modules, @"modules",
						 drones, @"drones",
						 implants, @"implants",
						 boosters, @"boosters",nil];
	return [NSDictionary dictionaryWithObjectsAndKeys:
			[NSNumber numberWithInteger:fitID], @"fitID",
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
	if (fitID <= 0) {
		if (fits.count == 0)
			fitID = 1;
		else
			fitID = [[[fits lastObject] valueForKey:@"fitID"] integerValue] + 1;
	}
	NSDictionary *record = [self dictionary];
	
	BOOL bFind = NO;
	NSInteger i = 0;
	for (NSDictionary *item in fits) {
		if ([[item valueForKey:@"fitID"] integerValue] == fitID) {
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

@end

@implementation Fit(Private)

- (void) clear {
	character.reset();
}

@end