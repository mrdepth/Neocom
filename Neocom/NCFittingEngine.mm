//
//  NCFittingEngine.m
//  Neocom
//
//  Created by Artem Shimanski on 18.09.15.
//  Copyright © 2015 Artem Shimanski. All rights reserved.
//

#import "NCFittingEngine.h"
#import "NCShipFit.h"
#import "NCPOSFit.h"
#import "NCDatabase.h"
#import <EVEAPI/EVEAPI.h>
#import "NCKillMail.h"

@interface NCShipFit()
@property (nonatomic, strong, readwrite) NCFittingEngine* engine;
@property (nonatomic, assign, readwrite) std::shared_ptr<eufe::Character> pilot;
@end

@interface NCPOSFit()
@property (nonatomic, strong, readwrite) NCFittingEngine* engine;
@end

@interface NCFittingEngine()
@property (nonatomic, strong, readwrite) NSManagedObjectContext* databaseManagedObjectContext;
@property (nonatomic, strong, readwrite) NSManagedObjectContext* storageManagedObjectContext;
//@property (nonatomic, strong) dispatch_queue_t privateQueue;
- (NCLoadoutDataShip*) loadoutDataShipWithAsset:(EVEAssetListItem*) asset;
- (NCLoadoutDataShip*) loadoutDataShipWithAPILoadout:(NAPISearchItem*) apiLoadout;
- (NCLoadoutDataShip*) loadoutDataShipWithKillMail:(NCKillMail*) killMail;
- (NCLoadoutDataShip*) loadoutDataShipWithDNA:(NSString*) dna;
- (NCLoadoutDataShip*) loadoutDataShipWithCRFitting:(CRFitting*) fitting;
- (NCLoadoutDataPOS*) loadoutPOSDataWithAsset:(EVEAssetListItem*) asset;
- (void)didReceiveMemoryWarning;

@end

@implementation NCFittingEngine
@synthesize engine = _engine;

- (id) init {
	if (self = [super init]) {
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveMemoryWarning) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
//		self.privateQueue = dispatch_queue_create(0, DISPATCH_QUEUE_SERIAL);
	}
	return self;
}

- (std::shared_ptr<eufe::Engine>) engine {
	@synchronized(self) {
		if (!_engine) {
			NSString* path = [[[NCDatabase sharedDatabase] databaseUpdateDirectory] stringByAppendingPathComponent:@"eufe.sqlite"];
			if (path) {
				try {
					_engine = std::make_shared<eufe::Engine>(std::make_shared<eufe::SqliteConnector>([path cStringUsingEncoding:NSUTF8StringEncoding]));
					return _engine;
				} catch (...) {
				}
			}
			_engine = std::make_shared<eufe::Engine>(std::make_shared<eufe::SqliteConnector>([[[NSBundle mainBundle] pathForResource:@"eufe" ofType:@"sqlite"] cStringUsingEncoding:NSUTF8StringEncoding]));
		}
		return _engine;
	}
}

- (void) dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)performBlockAndWait:(void (^)())block {
	[self.databaseManagedObjectContext performBlockAndWait:^{
		eufe::Engine::ScopedLock lock(self.engine);
		block();
	}];
}

- (void) performBlock:(void (^)())block {
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
		[self.databaseManagedObjectContext performBlock:^{
			eufe::Engine::ScopedLock lock(self.engine);
			block();
		}];
	});
}

- (void) loadShipFit:(NCShipFit*) fit {
	fit.engine = self;
	NCLoadoutDataShip* loadoutData = [self loadoutDataShipWithFit:fit];

	
	[self performBlockAndWait:^{
		NSMutableSet* charges = [NSMutableSet new];
		eufe::TypeID modeID = loadoutData.mode;

		for (NCLoadoutDataShipCargoItem* item in loadoutData.cargo) {
			NCDBInvType* type = [self.databaseManagedObjectContext invTypeWithTypeID:item.typeID];
			if (type.group.category.categoryID == NCChargeCategoryID) {
				[charges addObject:@(item.typeID)];
			}
		}
		
		if (!modeID) {
			NCDBEufeItemCategory* category = [self.databaseManagedObjectContext categoryWithSlot:NCDBEufeItemSlotMode size:fit.typeID race:nil];
			if (category) {
				NCDBEufeItemGroup* group = [category.itemGroups anyObject];
				NCDBEufeItem* item = [group.items anyObject];
				modeID = item.type.typeID;
			}
		}

		
//		CFTimeInterval t0 = CACurrentMediaTime();

		NSAssert(fit.pilot == nullptr, @"NCShipFit already loaded");
		auto pilot = self.engine->getGang()->addPilot();
		fit.pilot = pilot;
		auto ship = pilot->setShip(static_cast<eufe::TypeID>(fit.typeID));
//		CFTimeInterval t1 = CACurrentMediaTime();
//		NSLog(@"Fit loading time %f", t1 - t0);
		if (ship) {
			for (NSString* key in @[@"subsystems", @"rigSlots", @"lowSlots", @"medSlots", @"hiSlots"]) {
				for (NCLoadoutDataShipModule* item in [loadoutData valueForKey:key]) {
					auto module = ship->addModule(item.typeID);
					if (module) {
						module->setPreferredState(item.state);
						if (item.chargeID)
							module->setCharge(item.chargeID);
					}
				}
			}
			
			for (NCLoadoutDataShipDrone* item in loadoutData.drones) {
				for (int n = item.count; n > 0; n--) {
					auto drone = ship->addDrone(item.typeID);
					if (!drone)
						break;
					drone->setActive(item.active);
				}
			}

			for (NCLoadoutDataShipImplant* item in loadoutData.implants)
				pilot->addImplant(item.typeID);
			
			for (NCLoadoutDataShipBooster* item in loadoutData.boosters)
				pilot->addBooster(item.typeID);
			
			for (NSNumber* typeID in charges) {
				eufe::TypeID chargeID = [typeID intValue];
				for (auto module: ship->getModules()) {
					if (!module->getCharge())
						module->setCharge(chargeID);
				}
			}
			if (ship->getFreeSlots(eufe::Module::SLOT_MODE) > 0) {
				if (modeID > 0)
					ship->addModule(modeID);
			}
		}
	}];
}

- (void) loadPOSFit:(NCPOSFit *)fit {
	fit.engine = self;
	__block NCLoadoutDataPOS* loadoutData;
	if (fit.loadoutID) {
		[self.storageManagedObjectContext performBlockAndWait:^{
			NCLoadout* loadout = [self.storageManagedObjectContext existingObjectWithID:fit.loadoutID error:nil];
			if ([loadout.data.data isKindOfClass:[NCLoadoutDataPOS class]])
				loadoutData = (NCLoadoutDataPOS*) loadout.data.data;
		}];
	}
	else if (fit.asset)
		loadoutData = [self loadoutPOSDataWithAsset:fit.asset];
	
	[self performBlockAndWait:^{
		auto controlTower = self.engine->setControlTower(fit.typeID);
		if (controlTower) {
			for (NCLoadoutDataPOSStructure* item in loadoutData.structures) {
				for (int n = item.count; n > 0; n--) {
					auto structure = controlTower->addStructure(item.typeID);
					if (!structure)
						break;
					structure->setState(item.state);
					if (item.chargeID)
						structure->setCharge(item.chargeID);
				}
			}
		}
	}];
}

- (NCLoadoutDataShip*) loadoutDataShipWithFit:(NCShipFit *)fit {
	__block NCLoadoutDataShip* loadoutData;
	if (fit.loadoutID) {
		[self.storageManagedObjectContext performBlockAndWait:^{
			NCLoadout* loadout = [self.storageManagedObjectContext existingObjectWithID:fit.loadoutID error:nil];
			if ([loadout.data.data isKindOfClass:[NCLoadoutDataShip class]])
				loadoutData = (NCLoadoutDataShip*) loadout.data.data;
		}];
	}
	else if (fit.apiLadout)
		loadoutData = [self loadoutDataShipWithAPILoadout:fit.apiLadout];
	else if (fit.asset)
		loadoutData = [self loadoutDataShipWithAsset:fit.asset];
	else if (fit.killMail)
		loadoutData = [self loadoutDataShipWithKillMail:fit.killMail];
	else if (fit.dna)
		loadoutData = [self loadoutDataShipWithDNA:fit.dna];
	else if (fit.crFitting)
		loadoutData = [self loadoutDataShipWithCRFitting:fit.crFitting];
	return loadoutData;
}

#pragma mark - Private


- (NCLoadoutDataShip*) loadoutDataShipWithAsset:(EVEAssetListItem*) asset {
	NCLoadoutDataShip* loadoutData = [NCLoadoutDataShip new];
	[self.databaseManagedObjectContext performBlockAndWait:^{
		
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
		
		loadoutData.hiSlots = hiSlots;
		loadoutData.medSlots = medSlots;
		loadoutData.lowSlots = lowSlots;
		loadoutData.rigSlots = rigSlots;
		loadoutData.subsystems = subsystems;
		loadoutData.drones = drones;
		loadoutData.cargo = cargo;
		loadoutData.implants = @[];
		loadoutData.boosters = @[];

	}];
	return loadoutData;
}

- (NCLoadoutDataShip*) loadoutDataShipWithAPILoadout:(NAPISearchItem*) apiLoadout {
	NCLoadoutDataShip* loadoutData = [NCLoadoutDataShip new];
	[self.databaseManagedObjectContext performBlockAndWait:^{
		NSArray* components = [apiLoadout.canonicalName componentsSeparatedByString:@"|"];
		if (components.count > 0) {
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
					
					NCDBInvType *type = [self.databaseManagedObjectContext invTypeWithTypeID:typeID];
					if (!type)
						continue;
					
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
			
			loadoutData.hiSlots = hiSlots;
			loadoutData.medSlots = medSlots;
			loadoutData.lowSlots = lowSlots;
			loadoutData.rigSlots = rigSlots;
			loadoutData.subsystems = subsystems;
			loadoutData.drones = drones;
			loadoutData.cargo = @[];
			loadoutData.implants = implants;
			loadoutData.boosters = boosters;
			
		}
	}];
	return loadoutData;
}

- (NCLoadoutDataShip*) loadoutDataShipWithKillMail:(NCKillMail*) killMail {
	NCLoadoutDataShip* loadoutData = [NCLoadoutDataShip new];
	[self.databaseManagedObjectContext performBlockAndWait:^{
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
				NCDBInvType* type = [self.databaseManagedObjectContext invTypeWithTypeID:item.typeID];
				if (type.category == NCTypeCategoryModule) {
					for (int j = 0; j < item.qty; j++) {
						NCLoadoutDataShipModule* module = [NCLoadoutDataShipModule new];
						module.typeID = item.typeID;
						module.state = eufe::Module::STATE_ACTIVE;
						[slots[i] addObject:module];
						modules[@(item.flag)] = module;
					}
				}
				else
					charges[@(item.flag)] = type;
			}
		}
		
		[charges enumerateKeysAndObjectsUsingBlock:^(NSNumber* key, NCDBInvType* obj, BOOL *stop) {
			NCLoadoutDataShipModule* module = modules[key];
			if (module)
				module.chargeID = obj.typeID;
		}];
		
		for (NCKillMailItem* item in killMail.droneBay) {
			NCDBInvType* type = [self.databaseManagedObjectContext invTypeWithTypeID:item.typeID];
			NCLoadoutDataShipDrone* drone = dronesDic[@(type.typeID)];
			if (!drone) {
				drone = [NCLoadoutDataShipDrone new];
				drone.typeID = type.typeID;
				drone.active = true;
				dronesDic[@(type.typeID)] = drone;
			}
			drone.count += item.qty;
		}
		for (NCKillMailItem* item in killMail.cargo) {
			NCLoadoutDataShipCargoItem* cargo = cargoDic[@(item.typeID)];
			if (!cargo) {
				cargo = [NCLoadoutDataShipCargoItem new];
				cargo.typeID = item.typeID;
				cargoDic[@(item.typeID)] = cargo;
			}
			cargo.count += item.qty;
		}
		
		drones = [dronesDic allValues];
		cargo = [cargoDic allValues];
		
		loadoutData.hiSlots = hiSlots;
		loadoutData.medSlots = medSlots;
		loadoutData.lowSlots = lowSlots;
		loadoutData.rigSlots = rigSlots;
		loadoutData.subsystems = subsystems;
		loadoutData.drones = drones;
		loadoutData.cargo = cargo;
		loadoutData.implants = @[];
		loadoutData.boosters = @[];
	}];
	return loadoutData;
}

- (NCLoadoutDataShip*) loadoutDataShipWithDNA:(NSString*) dna {
	NCLoadoutDataShip* loadoutData = [NCLoadoutDataShip new];
	[self.databaseManagedObjectContext performBlockAndWait:^{
		NSMutableArray* records = [[dna componentsSeparatedByString:@":"] mutableCopy];
		if (records.count == 0) {
			return;
		}
		
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
				NCDBInvType* type = [self.databaseManagedObjectContext invTypeWithTypeID:typeID];
				
				
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
		
		loadoutData.hiSlots = hiSlots;
		loadoutData.medSlots = medSlots;
		loadoutData.lowSlots = lowSlots;
		loadoutData.rigSlots = rigSlots;
		loadoutData.subsystems = subsystems;
		loadoutData.drones = drones;
		loadoutData.cargo = cargo;
		loadoutData.implants = @[];
		loadoutData.boosters = @[];
	}];
	return loadoutData;
}

- (NCLoadoutDataShip*) loadoutDataShipWithCRFitting:(CRFitting *)fitting {
	NCLoadoutDataShip* loadoutData = [NCLoadoutDataShip new];
	[self.databaseManagedObjectContext performBlockAndWait:^{
		
		NSMutableArray* hiSlots = [NSMutableArray new];
		NSMutableArray* medSlots = [NSMutableArray new];
		NSMutableArray* lowSlots = [NSMutableArray new];
		NSMutableArray* rigSlots = [NSMutableArray new];
		NSMutableArray* subsystems = [NSMutableArray new];
		NSArray* drones = nil;
		NSArray* cargo = nil;
		NSMutableDictionary* dronesDic = [NSMutableDictionary new];
		NSMutableDictionary* cargoDic = [NSMutableDictionary new];
		
		for (CRFittingItem* item in fitting.items) {
			if (item.flag >= EVEInventoryFlagHiSlot0 && item.flag <= EVEInventoryFlagHiSlot7) {
				for (int i = 0; i < item.quantity; i++) {
					NCLoadoutDataShipModule* module = [NCLoadoutDataShipModule new];
					module.typeID = item.type.typeID;
					module.state = eufe::Module::STATE_ACTIVE;
					[hiSlots addObject:module];
				}
			}
			else if (item.flag >= EVEInventoryFlagMedSlot0 && item.flag <= EVEInventoryFlagMedSlot7) {
				for (int i = 0; i < item.quantity; i++) {
					NCLoadoutDataShipModule* module = [NCLoadoutDataShipModule new];
					module.typeID = item.type.typeID;
					module.state = eufe::Module::STATE_ACTIVE;
					[medSlots addObject:module];
				}
			}
			else if (item.flag >= EVEInventoryFlagLoSlot0 && item.flag <= EVEInventoryFlagLoSlot7) {
				for (int i = 0; i < item.quantity; i++) {
					NCLoadoutDataShipModule* module = [NCLoadoutDataShipModule new];
					module.typeID = item.type.typeID;
					module.state = eufe::Module::STATE_ACTIVE;
					[lowSlots addObject:module];
				}
			}
			else if (item.flag >= EVEInventoryFlagRigSlot0 && item.flag <= EVEInventoryFlagRigSlot7) {
				for (int i = 0; i < item.quantity; i++) {
					NCLoadoutDataShipModule* module = [NCLoadoutDataShipModule new];
					module.typeID = item.type.typeID;
					module.state = eufe::Module::STATE_ACTIVE;
					[rigSlots addObject:module];
				}
			}
			else if (item.flag >= EVEInventoryFlagSubSystem0 && item.flag <= EVEInventoryFlagSubSystem7) {
				for (int i = 0; i < item.quantity; i++) {
					NCLoadoutDataShipModule* module = [NCLoadoutDataShipModule new];
					module.typeID = item.type.typeID;
					module.state = eufe::Module::STATE_ACTIVE;
					[subsystems addObject:module];
				}
			}
			else if (item.flag == EVEInventoryFlagDroneBay) {
				NCLoadoutDataShipDrone* drone = dronesDic[@(item.type.typeID)];
				if (!drone) {
					drone = [NCLoadoutDataShipDrone new];
					drone.typeID = item.type.typeID;
					drone.active = true;
					dronesDic[@(item.type.typeID)] = drone;
				}
				drone.count += item.quantity;
			}
			else {
				NCLoadoutDataShipCargoItem* cargo = cargoDic[@(item.type.typeID)];
				if (!cargo) {
					cargo = [NCLoadoutDataShipCargoItem new];
					cargo.typeID = item.type.typeID;
					cargoDic[@(item.type.typeID)] = cargo;
				}
				cargo.count += item.quantity;
			}
		}
		
		drones = [dronesDic allValues];
		cargo = [cargoDic allValues];
		
		loadoutData.hiSlots = hiSlots;
		loadoutData.medSlots = medSlots;
		loadoutData.lowSlots = lowSlots;
		loadoutData.rigSlots = rigSlots;
		loadoutData.subsystems = subsystems;
		loadoutData.drones = drones;
		loadoutData.cargo = cargo;
		loadoutData.implants = @[];
		loadoutData.boosters = @[];
		
	}];
	return loadoutData;
}

- (NCLoadoutDataPOS*) loadoutPOSDataWithAsset:(EVEAssetListItem*) asset {
	NCLoadoutDataPOS* loadoutData = [NCLoadoutDataPOS new];
	[self.databaseManagedObjectContext performBlockAndWait:^{
		NSMutableDictionary* structuresDic = [NSMutableDictionary new];
		for (EVEAssetListItem* item in asset.contents) {
			NCDBInvType* type = [self.databaseManagedObjectContext invTypeWithTypeID:item.typeID];
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
		loadoutData.structures = [structuresDic allValues];
	}];
	return loadoutData;
}

- (NSManagedObjectContext*) databaseManagedObjectContext {
	@synchronized(self) {
		if (!_databaseManagedObjectContext)
			_databaseManagedObjectContext = [[NCDatabase sharedDatabase] createManagedObjectContextWithConcurrencyType:NSPrivateQueueConcurrencyType];
			//_databaseManagedObjectContext = [[NCDatabase sharedDatabase] createManagedObjectContextWithConcurrencyType:NSMainQueueConcurrencyType];
		return _databaseManagedObjectContext;
	}
}

- (NSManagedObjectContext*) storageManagedObjectContext {
	@synchronized(self) {
		if (!_storageManagedObjectContext)
			_storageManagedObjectContext = [[NCStorage sharedStorage] createManagedObjectContextWithConcurrencyType:NSPrivateQueueConcurrencyType];
		//_databaseManagedObjectContext = [[NCDatabase sharedDatabase] createManagedObjectContextWithConcurrencyType:NSMainQueueConcurrencyType];
		return _storageManagedObjectContext;
	}
}

- (void)didReceiveMemoryWarning {
	self.databaseManagedObjectContext = nil;
}


@end

@implementation NCFittingEngineItemPointer
@synthesize item = _item;

+ (instancetype) pointerWithItem:(std::shared_ptr<eufe::Item>) item {
	return [[self alloc] initWithItem:item];
}

- (id) initWithItem:(std::shared_ptr<eufe::Item>) item {
	if (self = [super init]) {
		_item = item;
	}
	return self;
}


@end