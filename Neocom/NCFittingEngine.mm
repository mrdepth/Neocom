//
//  NCFittingEngine.m
//  Neocom
//
//  Created by Artem Shimanski on 18.09.15.
//  Copyright © 2015 Artem Shimanski. All rights reserved.
//

#import "NCFittingEngine.h"
#import "NCShipFit.h"
#import "NCDatabase.h"
#import <EVEAPI/EVEAPI.h>

@interface NCShipFit()
@property (nonatomic, strong, readwrite) NCFittingEngine* engine;
@property (nonatomic, assign, readwrite) std::shared_ptr<eufe::Character> pilot;
@end

@interface NCFittingEngine()
@property (nonatomic, strong, readwrite) NSManagedObjectContext* databaseManagedObjectContext;
@property (nonatomic, strong, readwrite) NSManagedObjectContext* storageManagedObjectContext;
//@property (nonatomic, strong) dispatch_queue_t privateQueue;
- (NCLoadoutDataShip*) loadoutShipDataWithAsset:(EVEAssetListItem*) asset;
- (NCLoadoutDataShip*) loadoutShipDataWithAPILoadout:(NAPISearchItem*) apiLoadout;
- (NCLoadoutDataShip*) loadoutShipDataWithKillMail:(NCKillMail*) killMail;
- (NCLoadoutDataShip*) loadoutShipDataWithDNA:(NSString*) dna;
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
		if (!_engine)
			_engine = std::make_shared<eufe::Engine>(std::make_shared<eufe::SqliteConnector>([[[NSBundle mainBundle] pathForResource:@"eufe" ofType:@"sqlite"] cStringUsingEncoding:NSUTF8StringEncoding]));
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
	__block NCLoadoutDataShip* loadoutData;
	if (fit.loadoutID) {
		[self.storageManagedObjectContext performBlockAndWait:^{
			NCLoadout* loadout = [self.storageManagedObjectContext objectWithID:fit.loadoutID];
			if ([loadout.data.data isKindOfClass:[NCLoadoutDataShip class]])
				loadoutData = (NCLoadoutDataShip*) loadout.data.data;
		}];
	}
	
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

		
		NSAssert(fit.pilot == nullptr, @"NCShipFit already loaded");
		auto pilot = self.engine->getGang()->addPilot();
		fit.pilot = pilot;
		auto ship = pilot->setShip(static_cast<eufe::TypeID>(fit.typeID));
		if (ship) {
			for (NSString* key in @[@"subsystems", @"rigSlots", @"lowSlots", @"medSlots", @"hiSlots"]) {
				for (NCLoadoutDataShipModule* item in [loadoutData valueForKey:key]) {
					auto module = ship->addModule(item.typeID);
					if (module) {
						module->setState(item.state);
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

#pragma mark - Private

- (NCLoadoutDataShip*) loadoutShipDataWithAsset:(EVEAssetListItem*) asset {
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

- (NCLoadoutDataShip*) loadoutShipDataWithAPILoadout:(NAPISearchItem*) apiLoadout {
	NCLoadoutDataShip* loadoutData = [NCLoadoutDataShip new];
	[self.databaseManagedObjectContext performBlockAndWait:^{
	}];
	return loadoutData;
}

- (NCLoadoutDataShip*) loadoutShipDataWithKillMail:(NCKillMail*) killMail {
	NCLoadoutDataShip* loadoutData = [NCLoadoutDataShip new];
	[self.databaseManagedObjectContext performBlockAndWait:^{
	}];
	return loadoutData;
}

- (NCLoadoutDataShip*) loadoutShipDataWithDNA:(NSString*) dna {
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