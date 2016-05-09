//
//  NCPlanetaryViewController.m
//  Neocom
//
//  Created by Артем Шиманский on 24.03.15.
//  Copyright (c) 2015 Artem Shimanski. All rights reserved.
//

#import "NCPlanetaryViewController.h"
#import "UIColor+Neocom.h"
#import "NSString+Neocom.h"
#import "NCDatabaseTypeInfoViewController.h"
#import "NCFittingEngine.h"
#import "NCBarChartView.h"
#import "NCPlanetaryCell.h"
#import "NCExtractorCell.h"
#import "NCStorageCell.h"
#import "NCFactoryCell.h"
#import "NSString+Neocom.h"
#import "NSNumberFormatter+Neocom.h"
#import "NSAttributedString+Neocom.h"

@interface NCPlanetaryViewControllerDataColony : NSObject<NSCoding>
@property (nonatomic, strong) EVEPlanetaryColoniesItem* colony;
@property (nonatomic, strong) EVEPlanetaryPins* pins;
@property (nonatomic, strong) EVEPlanetaryRoutes* routes;
@property (nonatomic, assign) float security;
@property (nonatomic, strong) NSArray* facilities;
@property (nonatomic, strong) NSDate* currentTime;
@property (nonatomic, strong) NSDate* cacheDate;
@end


@interface NCPlanetaryViewControllerData : NSObject<NSCoding>
@property (nonatomic, strong) NSArray* colonies;
@end

@interface NCPlanetaryViewControllerSection : NSObject
@property (nonatomic, strong) NCPlanetaryViewControllerDataColony* colony;
@property (nonatomic, strong) NSArray* rows;
@property (nonatomic, assign) BOOL warning;
@end

@interface NCPlanetaryViewControllerRow : NSObject
@property (nonatomic, strong) EVEPlanetaryPinsItem* pin;
@property (nonatomic, strong) NSString* pinName;

@property (nonatomic, assign) std::shared_ptr<const dgmpp::Facility> facility;
@property (nonatomic, strong) NSDate* startDate;
@property (nonatomic, strong) NSDate* endDate;
@property (nonatomic, assign) int32_t order;
@property (nonatomic, assign) BOOL active;
@property (nonatomic, assign) int32_t tier;
@property (nonatomic, assign) int32_t typeID;
@end

@interface NCPlanetaryViewControllerExtractorRow : NCPlanetaryViewControllerRow
@property (nonatomic, strong) NSArray* bars;
@property (nonatomic, assign) std::shared_ptr<const dgmpp::ProductionState> currentState;
@property (nonatomic, assign) std::shared_ptr<const dgmpp::ProductionState> nextWasteState;
@property (nonatomic, assign) uint32_t allTimeYield;
@property (nonatomic, assign) uint32_t allTimeWaste;
@property (nonatomic, assign) uint32_t maxProduct;

@end

@interface NCPlanetaryViewControllerStorageRow : NCPlanetaryViewControllerRow
@property (nonatomic, assign) std::shared_ptr<const dgmpp::State> currentState;
@property (nonatomic, strong) NSArray* bars;
@end

@interface NCPlanetaryViewControllerFactoryRow : NCPlanetaryViewControllerRow {
	std::map<dgmpp::TypeID, uint32_t> _ratio;
	std::map<dgmpp::TypeID, double> _shortageTime;
	std::list<std::shared_ptr<dgmpp::IndustryFacility>> _factories;
}

@property (nonatomic, assign) double productionTime;
@property (nonatomic, assign) double idleTime;
@property (nonatomic, assign) double extrapolatedProductionTime;
@property (nonatomic, assign) double extrapolatedIdleTime;
@property (nonatomic, assign) std::map<dgmpp::TypeID, uint32_t>& ratio;
//@property (nonatomic, assign) std::map<dgmpp::TypeID, double>& shortageTime;
@property (nonatomic, assign) std::list<std::shared_ptr<dgmpp::IndustryFacility>>& factories;
@property (nonatomic, assign) std::shared_ptr<const dgmpp::ProductionState> lastState;

@end


@implementation NCPlanetaryViewControllerSection
@end

@implementation NCPlanetaryViewControllerRow
@end

@implementation NCPlanetaryViewControllerExtractorRow
@end

@implementation NCPlanetaryViewControllerStorageRow
@end

@implementation NCPlanetaryViewControllerFactoryRow
@end

@implementation NCPlanetaryViewControllerDataColony

- (id) initWithCoder:(NSCoder *)aDecoder {
	if (self = [super init]) {
		self.colony = [aDecoder decodeObjectForKey:@"colony"];
		self.security = [aDecoder decodeFloatForKey:@"security"];
		
		self.facilities = [aDecoder decodeObjectForKey:@"facilities"];
		self.currentTime = [aDecoder decodeObjectForKey:@"currentTime"];
		self.cacheDate = [aDecoder decodeObjectForKey:@"cacheDate"];

		self.pins = [aDecoder decodeObjectForKey:@"pins"];
		self.routes = [aDecoder decodeObjectForKey:@"routes"];

		if (!self.facilities)
			self.facilities = @[];
	}
	return self;
}

- (void) encodeWithCoder:(NSCoder *)aCoder {
	if (self.colony)
		[aCoder encodeObject:self.colony forKey:@"colony"];
	[aCoder encodeFloat:self.security forKey:@"security"];
	
	[aCoder encodeObject:self.facilities forKey:@"facilities"];
	[aCoder encodeObject:self.currentTime forKey:@"currentTime"];
	[aCoder encodeObject:self.cacheDate forKey:@"cacheDate"];

	[aCoder encodeObject:self.pins forKey:@"pins"];
	[aCoder encodeObject:self.routes forKey:@"routes"];
}


@end

@implementation NCPlanetaryViewControllerData

- (id) initWithCoder:(NSCoder *)aDecoder {
	if (self = [super init]) {
		self.colonies = [aDecoder decodeObjectForKey:@"colonies"];
		
		if (!self.colonies)
			self.colonies = @[];
	}
	return self;
}

- (void) encodeWithCoder:(NSCoder *)aCoder {
	if (self.colonies)
		[aCoder encodeObject:self.colonies forKey:@"colonies"];
}

@end


@interface NCPlanetaryViewController ()
@property (nonatomic, strong) NSDateFormatter* dateFormatter;
//@property (nonatomic, strong) NSMutableDictionary* solarSystems;
@property (nonatomic, strong) NCAccount* account;
@property (nonatomic, strong) NSArray* sections;
@property (nonatomic, strong) NCFittingEngine* engine;
@end

@implementation NCPlanetaryViewController

- (void)viewDidLoad
{
	[super viewDidLoad];
	self.dateFormatter = [[NSDateFormatter alloc] init];
	[self.dateFormatter setDateFormat:@"yyyy.MM.dd HH:mm"];
	[self.dateFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"]];
	self.account = [NCAccount currentAccount];
}

- (void)didReceiveMemoryWarning
{
	[super didReceiveMemoryWarning];
	// Dispose of any resources that can be recreated.
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	if ([segue.identifier isEqualToString:@"NCDatabaseTypeInfoViewController"]) {
		NCDatabaseTypeInfoViewController* controller;
		if ([segue.destinationViewController isKindOfClass:[UINavigationController class]])
			controller = [segue.destinationViewController viewControllers][0];
		else
			controller = segue.destinationViewController;
		
		controller.typeID = [[sender object] objectID];
	}
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return self.sections.count;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)sectionIndex {
	NCPlanetaryViewControllerSection* section = self.sections[sectionIndex];
	return section.rows.count;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	NCTableViewCell* cell = [tableView cellForRowAtIndexPath:indexPath];
	if (cell.object)
		[self performSegueWithIdentifier:@"NCDatabaseTypeInfoViewController" sender:cell];
}

#pragma mark - NCTableViewController

- (void) loadCacheData:(id)cacheData withCompletionBlock:(void (^)())completionBlock {
	NCPlanetaryViewControllerData* data = cacheData;
	self.backgrountText = data.colonies.count > 0 ? nil : NSLocalizedString(@"No Results", nil);
	
	self.engine = [NCFittingEngine new];
	
	NSProgress* totalProgress = [NSProgress progressWithTotalUnitCount:2];
	self.progress = totalProgress;
	[totalProgress becomeCurrentWithPendingUnitCount:1];
	[self simulateProgress:[NSProgress progressWithTotalUnitCount:30]];
	[totalProgress resignCurrent];
	
	[self.engine performBlock:^{
		NSMutableArray* sections = [NSMutableArray new];
		UIColor* green = [UIColor colorWithRed:0 green:0.6 blue:0 alpha:1];
		UIColor* red = [UIColor colorWithRed:0.8 green:0 blue:0 alpha:1];

		[totalProgress becomeCurrentWithPendingUnitCount:1];
		NSProgress* progress = [NSProgress progressWithTotalUnitCount:data.colonies.count];
		[totalProgress resignCurrent];
		
		for (NCPlanetaryViewControllerDataColony* colony in data.colonies) {

			//Initialize Colony
			NSTimeInterval serverTime = [[colony.pins.eveapi serverTimeWithLocalTime:[NSDate date]] timeIntervalSinceReferenceDate];
			auto planet = self.engine.engine->setPlanet(colony.colony.planetTypeID);
			NSDate* lastUpdateDate = nil;
			
			for (EVEPlanetaryPinsItem* pin in colony.pins.pins) {
				try {
					auto facility = planet->findFacility(pin.pinID);
					if (!facility) {
						facility = planet->addFacility(pin.typeID, pin.pinID);
						switch (facility->getGroupID()) {
							case dgmpp::ExtractorControlUnit::GROUP_ID: {
								auto ecu = std::dynamic_pointer_cast<dgmpp::ExtractorControlUnit>(facility);
								ecu->setLaunchTime([pin.lastLaunchTime timeIntervalSinceReferenceDate]);
								ecu->setInstallTime([pin.installTime timeIntervalSinceReferenceDate]);
								ecu->setExpiryTime([pin.expiryTime timeIntervalSinceReferenceDate]);
								ecu->setCycleTime(pin.cycleTime * 60);
								ecu->setQuantityPerCycle(pin.quantityPerCycle);
								break;
							}
							case dgmpp::IndustryFacility::GROUP_ID: {
								auto factory = std::dynamic_pointer_cast<dgmpp::IndustryFacility>(facility);
								factory->setLaunchTime([pin.lastLaunchTime timeIntervalSinceReferenceDate]);
								factory->setSchematic(pin.schematicID);
								break;
							}
							default:
								break;
						}
					}
					
					lastUpdateDate = lastUpdateDate ? pin.lastLaunchTime ? [lastUpdateDate laterDate:pin.lastLaunchTime] : lastUpdateDate : pin.lastLaunchTime;
					if (pin.contentQuantity > 0 && pin.contentTypeID)
						facility->addCommodity(pin.contentTypeID, pin.contentQuantity);
				} catch (...) {}
			}
			for (EVEPlanetaryRoutesItem* route in colony.routes.routes) {
				auto source = planet->findFacility(route.sourcePinID);
				auto destination = planet->findFacility(route.destinationPinID);
				if (source && destination)
					planet->addRoute(source, destination, dgmpp::Commodity(self.engine.engine, route.contentTypeID, route.quantity), route.routeID);
			}
			lastUpdateDate = colony.colony.lastUpdate;
			planet->setLastUpdate(lastUpdateDate ? [lastUpdateDate timeIntervalSinceReferenceDate] : [colony.colony.lastUpdate timeIntervalSinceReferenceDate]);
			planet->simulate();
			
			//Process simulation results
			NCPlanetaryViewControllerSection* section = [NCPlanetaryViewControllerSection new];
			section.colony = colony;
			
			NSMutableArray* rows = [NSMutableArray new];
			NSMutableDictionary* factories = [NSMutableDictionary new];
			NSMutableArray* chartRows = [NSMutableArray new];
			
			for (const auto& facility: planet->getFacilities()) {
				size_t numberOfStates = facility->numberOfStates();
				
				EVEPlanetaryPinsItem* pin =  [[colony.pins.pins filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"pinID == %qi", facility->getIdentifier()]] lastObject];

				switch (facility->getGroupID()) {
					case dgmpp::ExtractorControlUnit::GROUP_ID: {
						NSMutableArray* segments = [NSMutableArray new];
						NCPlanetaryViewControllerExtractorRow* row = [NCPlanetaryViewControllerExtractorRow new];
						row.pinName = [NSString stringWithCString:facility->getFacilityName().c_str() encoding:NSUTF8StringEncoding];
						row.facility = facility;
						auto ecu = std::dynamic_pointer_cast<dgmpp::ExtractorControlUnit>(facility);

						double startTime = ecu->getInstallTime();
						double cycleTime = ecu->getCycleTime();

						if (numberOfStates > 0) {
							uint32_t allTimeYield = 0;
							uint32_t allTimeWaste = 0;

							auto firstState = ecu->getStates().front();
							startTime = firstState->getTimestamp();
							double maxH = 0;
							if (cycleTime > 0) {
								for(double time = ecu->getInstallTime(); time < firstState->getTimestamp(); time += cycleTime) {
									double yield = ecu->getYieldAtTime(time);
									maxH = std::max(yield, maxH);
									allTimeYield += yield;
								}
							}

							std::shared_ptr<const dgmpp::ProductionState> lastState;
							std::shared_ptr<const dgmpp::ProductionState> firstWasteState;
							for (const auto& state: ecu->getStates()) {
								auto ecuState = std::dynamic_pointer_cast<const dgmpp::ProductionState>(state);
								auto ecuCycle = ecuState->getCurrentCycle();

								if (!row.currentState && serverTime < ecuState->getTimestamp())
									row.currentState = lastState;

								if (ecuCycle) {
									auto yield = ecuCycle->getYield().getQuantity();
									auto waste = ecuCycle->getWaste().getQuantity();
									auto launchTime = ecuState->getTimestamp();
									
									NCBarChartSegment* segment = [NCBarChartSegment new];
									segment.color0 = green;
									segment.color1 = red;
									segment.x = launchTime;
									segment.w = cycleTime;
									segment.h0 = yield;
									segment.h1 = waste;
									maxH = std::max(segment.h0 + segment.h1, maxH);
									[segments addObject:segment];
									
									allTimeYield += yield;
									allTimeWaste += waste;
									
									if (waste > 0 && !firstWasteState && launchTime > serverTime)
										firstWasteState = ecuState;

								}
								lastState = ecuState;
							}

							if (maxH > 0) {
								for (NCBarChartSegment* segment in segments) {
									segment.h0 /= maxH;
									segment.h1 /= maxH;
								}
							}
							
							row.nextWasteState = firstWasteState;
							row.allTimeYield = allTimeYield;
							row.allTimeWaste = allTimeWaste;
							row.startDate = [NSDate dateWithTimeIntervalSinceReferenceDate:startTime];
							if (lastState)
								row.endDate = [NSDate dateWithTimeIntervalSinceReferenceDate:lastState->getTimestamp()];
							else
								row.endDate = row.startDate;
							
							row.bars = segments;
							row.maxProduct = maxH;
							[chartRows addObject:row];
						}
						row.pin = pin;
						row.order = 0;
						row.active = segments.count > 0;
						row.typeID = ecu->getOutput().getTypeID();
						[rows addObject:row];
						break;
					}
					case dgmpp::IndustryFacility::GROUP_ID: {
						auto factory = std::dynamic_pointer_cast<dgmpp::IndustryFacility>(facility);
						if (factory->routed()) {
							auto schematic = factory->getSchematic();
							NCPlanetaryViewControllerFactoryRow* row = factories[@(schematic->getSchematicID())];
							if (!row) {
								row = [NCPlanetaryViewControllerFactoryRow new];
								row.pinName = [NSString stringWithCString:facility->getFacilityName().c_str() encoding:NSUTF8StringEncoding];
								row.order = 2;
								row.active = NO;
								row.tier = factory->getOutput().getTier();
								row.typeID = factory->getOutput().getTypeID();
								row.pin = pin;
								factories[@(schematic->getSchematicID())] = row;
								[rows addObject:row];
//								for (const auto& input: schematic->getInputs())
//									row.shortageTime[input.getTypeID()] = 0;
							}
							row.factories.push_back(factory);

							std::shared_ptr<const dgmpp::ProductionState> lastProductionState;
							std::shared_ptr<const dgmpp::ProductionState> firstProductionState;
							std::shared_ptr<const dgmpp::ProductionState> lastState;
							std::shared_ptr<const dgmpp::ProductionState> currentState;
							double extrapolatedEfficiency = -1;
							
							for (const auto& state: factory->getStates()) {
								auto factoryState = std::dynamic_pointer_cast<const dgmpp::ProductionState>(state);
								auto factoryCycle = factoryState->getCurrentCycle();
								
								if (!currentState && serverTime < factoryState->getTimestamp())
									currentState = lastState;

								if (factoryCycle && factoryCycle->getLaunchTime() == factoryState->getTimestamp()) {
									if (!firstProductionState)
										firstProductionState = factoryState;
									lastState = nullptr;
									extrapolatedEfficiency = -1;
									lastProductionState = factoryState;
								}
								else if (!factoryCycle) {
									if (!lastState)
										lastState = factoryState;
									extrapolatedEfficiency = factoryState->getEfficiency();
								}
							}
							if (!currentState)
								currentState = lastState;
							
							double duration = firstProductionState && currentState ? currentState->getTimestamp() - firstProductionState->getTimestamp() : 0;
							double extrapolatedDuration = firstProductionState && lastState ? lastState->getTimestamp() - firstProductionState->getTimestamp() : 0;
							if (duration < 0)
								duration = 0;
							
							double productionTime = currentState ? currentState->getEfficiency() * duration : 0;
							row.productionTime += productionTime;
							row.idleTime += duration - productionTime;
							
							double extrapolatedProductionTime = lastState ? lastState->getEfficiency() * extrapolatedDuration : 0;
							row.extrapolatedProductionTime += extrapolatedProductionTime;
							row.extrapolatedIdleTime += extrapolatedDuration - extrapolatedProductionTime;
							if (extrapolatedProductionTime > 0)
								row.active = YES;
							
							for (const auto& input: factory->getInputs()) {
								auto incomming = input->getSource()->getIncomming(input->getCommodity());
								row.ratio[incomming.getTypeID()] += incomming.getQuantity();
							}
							if (lastState) {
								if (!row.lastState)
									row.lastState = lastState;
								else if (row.lastState->getTimestamp() < lastState->getTimestamp())
									row.lastState = lastState;
							}
						}
						break;
					}
					case dgmpp::StorageFacility::GROUP_ID:
					case dgmpp::CommandCenter::GROUP_ID:
					case dgmpp::Spaceport::GROUP_ID: {
						NSMutableArray* segments = [NSMutableArray new];
						NCPlanetaryViewControllerStorageRow* row = [NCPlanetaryViewControllerStorageRow new];
						row.pinName = [NSString stringWithCString:facility->getFacilityName().c_str() encoding:NSUTF8StringEncoding];
						row.facility = facility;
						auto storage = std::dynamic_pointer_cast<dgmpp::StorageFacility>(facility);
						
						std::shared_ptr<const dgmpp::State> firstState;
						std::shared_ptr<const dgmpp::State> lastState;
						double capacity = storage->getCapacity();
						if (capacity > 0) {
							NCBarChartSegment* prevSegment;
							double timestamp = 0;
							for (const auto& state: storage->getStates()) {
								timestamp = state->getTimestamp();
								
								if (!row.currentState && serverTime < timestamp)
									row.currentState = lastState;

								NCBarChartSegment* segment = [NCBarChartSegment new];
								segment.color0 = green;
								segment.color1 = red;
								segment.x = timestamp;
								segment.h0 = state->getVolume() / capacity;
								[segments addObject:segment];
								
								prevSegment.w = timestamp - prevSegment.x;
								if (!firstState)
									firstState = state;
								
								lastState = state;
								prevSegment = segment;
							}
							prevSegment.w = std::numeric_limits<double>::infinity();
							
							if (!row.currentState)
								row.currentState = lastState;
						}
						

						row.startDate = [NSDate dateWithTimeIntervalSinceReferenceDate:firstState ? firstState->getTimestamp() : serverTime];
						if (lastState)
							row.endDate = [NSDate dateWithTimeIntervalSinceReferenceDate:lastState->getTimestamp() > serverTime ? lastState->getTimestamp() : serverTime];
						else
							row.endDate = [NSDate dateWithTimeIntervalSinceReferenceDate:serverTime];
						
						/*NSTimeInterval duration = [row.endDate timeIntervalSinceDate:row.startDate];
						NSTimeInterval startTime = [row.startDate timeIntervalSinceReferenceDate];
						if (duration > 0) {
							for (NCBarChartSegment* segment in segments) {
								segment.x = (segment.x - startTime) / duration;
								segment.w /= duration;
							}
						}*/
						row.order = 1;
						row.active = segments.count > 1 || (segments.count > 0 && storage->getVolume() > 0);
						row.pin = pin;
						row.bars = segments;
						[rows addObject:row];
						[chartRows addObject:row];

						break;
					}
					default:
						break;
				}
			}
			[rows sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"order" ascending:YES],
										 [NSSortDescriptor sortDescriptorWithKey:@"active" ascending:NO],
										 [NSSortDescriptor sortDescriptorWithKey:@"tier" ascending:NO],
										 [NSSortDescriptor sortDescriptorWithKey:@"typeID" ascending:YES]]];
			
			NSDate* globalStart = [chartRows valueForKeyPath:@"@min.startDate"];
			NSDate* globalEnd = [chartRows valueForKeyPath:@"@max.endDate"];
			NSTimeInterval duration = [globalEnd timeIntervalSinceDate:globalStart];
			NSTimeInterval startTime = [globalStart timeIntervalSinceReferenceDate];
			if (duration > 0) {
				for (id row in [chartRows filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"active==YES"]]) {
					[row setStartDate:globalStart];
					[row setEndDate:globalEnd];
					NSArray* segments = [row bars];
					for (NCBarChartSegment* segment in segments) {
						segment.x = (segment.x - startTime) / duration;
						if (std::isinf(segment.w))
							segment.w = 1.0 - segment.x;
						else
							segment.w /= duration;
					}
				}
			}
			
			BOOL halted = YES;
			for (NCPlanetaryViewControllerRow* row in rows) {
				if ([row isKindOfClass:[NCPlanetaryViewControllerExtractorRow class]]) {
					NCPlanetaryViewControllerExtractorRow* extractorRow = (NCPlanetaryViewControllerExtractorRow*) row;
					auto ecu = std::dynamic_pointer_cast<const dgmpp::ExtractorControlUnit>(extractorRow.facility);
					if (ecu) {
						if (extractorRow.nextWasteState || ecu->getExpiryTime() - serverTime < 3600 * 24)
							section.warning = YES;
						if (ecu->getExpiryTime() > serverTime)
							halted = NO;
					}
				}
				else if ([row isKindOfClass:[NCPlanetaryViewControllerFactoryRow class]]) {
					NCPlanetaryViewControllerFactoryRow* factoryRow = (NCPlanetaryViewControllerFactoryRow*) row;
					if (factoryRow.lastState) {
						if (factoryRow.lastState->getTimestamp() - serverTime < 3600 * 24)
							section.warning = YES;
						if (factoryRow.lastState->getTimestamp() > serverTime)
							halted = NO;
					}
				}
			}
			[rows filterUsingPredicate:[NSPredicate predicateWithFormat:@"active==YES"]];
			if (halted) {
				NCPlanetaryViewControllerRow* row = [NCPlanetaryViewControllerRow new];
				row.pinName = NSLocalizedString(@"Colony production has halted", nil);
				[rows insertObject:row atIndex:0];
				section.warning = YES;
			}
			section.rows = rows;
			[sections addObject:section];
			progress.completedUnitCount++;
		}
		
		dispatch_async(dispatch_get_main_queue(), ^{
			if (self.progress == totalProgress)
				self.progress = nil;
			self.sections = sections;
			completionBlock();
		});
	}];
}


- (void) downloadDataWithCachePolicy:(NSURLRequestCachePolicy)cachePolicy completionBlock:(void (^)(NSError *))completionBlock {
	__block NSError* lastError = nil;
	NCAccount* account = self.account;
	if (!account) {
		completionBlock(nil);
		return;
	}
	
	NSProgress* progress = [NSProgress progressWithTotalUnitCount:2];
	
	[account.managedObjectContext performBlock:^{
		EVEOnlineAPI* api = [[EVEOnlineAPI alloc] initWithAPIKey:account.eveAPIKey cachePolicy:cachePolicy];
		NCPlanetaryViewControllerData* data = [NCPlanetaryViewControllerData new];
		[api planetaryColoniesWithCompletionBlock:^(EVEPlanetaryColonies *result, NSError *error) {
			progress.completedUnitCount++;
			if (error)
				lastError = error;
			NSManagedObjectContext* databaseManagedObjectContext = [[NCDatabase sharedDatabase] createManagedObjectContext];
			[databaseManagedObjectContext performBlock:^{
				NSMutableArray* array = [NSMutableArray new];
				dispatch_group_t finishDispatchGroup = dispatch_group_create();
				
				[progress becomeCurrentWithPendingUnitCount:1];
				NSProgress* colonyProgress = [NSProgress progressWithTotalUnitCount:result.colonies.count * 2];
				[progress resignCurrent];
				
				for (EVEPlanetaryColoniesItem* item in result.colonies) {
					NCPlanetaryViewControllerDataColony* colony = [NCPlanetaryViewControllerDataColony new];
					NCDBMapSolarSystem* solarSystem = [databaseManagedObjectContext mapSolarSystemWithSolarSystemID:item.solarSystemID];
					colony.security = solarSystem ? solarSystem.security : 1.0;
					colony.colony = item;

					dispatch_group_enter(finishDispatchGroup);
					[api planetaryPinsWithPlanetID:item.planetID completionBlock:^(EVEPlanetaryPins *pins, NSError *error) {
						if (pins) {
							NSMutableDictionary* facilities = [NSMutableDictionary new];
							for (EVEPlanetaryPinsItem* pin in pins.pins) {
								facilities[@(pin.pinID)] = pin;
							}
							colony.facilities = [facilities allValues];
							colony.currentTime = pins.eveapi.currentTime;
							colony.cacheDate = pins.eveapi.cacheDate;
							colony.pins = pins;
							@synchronized(array) {
								[array addObject:colony];
							}
							@synchronized(colonyProgress) {
								colonyProgress.completedUnitCount++;
							}
							dispatch_group_leave(finishDispatchGroup);
						}
					} progressBlock:nil];
					
					dispatch_group_enter(finishDispatchGroup);
					[api planetaryRoutesWithPlanetID:item.planetID
									 completionBlock:^(EVEPlanetaryRoutes *routes, NSError *error) {
										 colony.routes = routes;
										 @synchronized(colonyProgress) {
											 colonyProgress.completedUnitCount++;
										 }
										 dispatch_group_leave(finishDispatchGroup);
									 } progressBlock:nil];

				}
				
				dispatch_group_notify(finishDispatchGroup, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
					[array sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"colony.planetName" ascending:YES]]];
					data.colonies = array;
					
					dispatch_async(dispatch_get_main_queue(), ^{
						[self saveCacheData:data cacheDate:[NSDate date] expireDate:[result.eveapi localTimeWithServerTime:result.eveapi.cachedUntil]];
						completionBlock(lastError);
						progress.completedUnitCount++;
					});
				});
			}];

		} progressBlock:nil];
	}];
}

- (void) didChangeAccount:(NSNotification *)notification {
	[super didChangeAccount:notification];
	self.account = [NCAccount currentAccount];
}

- (NSString*) tableView:(UITableView *)tableView cellIdentifierForRowAtIndexPath:(NSIndexPath *)indexPath {
	NCPlanetaryViewControllerSection* section = self.sections[indexPath.section];
	NCPlanetaryViewControllerRow* row = section.rows[indexPath.row];
	if ([row isKindOfClass:[NCPlanetaryViewControllerExtractorRow class]]) {
		if ([[row valueForKey:@"bars"] count] > 0)
			return @"NCExtractorCell";
		else
			return @"Cell";
	}
	else if ([row isKindOfClass:[NCPlanetaryViewControllerStorageRow class]]) {
		NCPlanetaryViewControllerStorageRow* storageRow = (NCPlanetaryViewControllerStorageRow*) row;
		if (storageRow.currentState)
			return @"NCStorageCell";
		else
			return @"Cell";
	}
	else if ([row isKindOfClass:[NCPlanetaryViewControllerFactoryRow class]]) {
		return @"NCFactoryCell";
	}
	else
		return @"Cell";
}

- (void) tableView:(UITableView *)tableView configureCell:(UITableViewCell*) tableViewCell forRowAtIndexPath:(NSIndexPath*) indexPath {
	NCPlanetaryViewControllerSection* section = self.sections[indexPath.section];
	NCPlanetaryViewControllerRow* row = section.rows[indexPath.row];
	NSDate* serverTime = [section.colony.pins.eveapi serverTimeWithLocalTime:[NSDate date]];
	NSTimeInterval serverTimestamp = [serverTime timeIntervalSinceReferenceDate];
	

	NSString* (^toString)(NSTimeInterval) = ^(NSTimeInterval time) {
		int32_t c = time;
		return [NSString stringWithFormat:@"%.2d:%.2d:%.2d", c / 3600, (c % 3600) / 60, c % 60];
	};
	
	NSAttributedString* title = [NSAttributedString attributedStringWithHTMLString:[NSString stringWithFormat:@"<color=lightText>%@</color> <color=white>%@</color>", row.pin.typeName, row.pinName]];
	
	if ([row isKindOfClass:[NCPlanetaryViewControllerExtractorRow class]]) {
		NCPlanetaryViewControllerExtractorRow* extractorRow = (NCPlanetaryViewControllerExtractorRow*) row;

		auto ecu = std::dynamic_pointer_cast<const dgmpp::ExtractorControlUnit>(extractorRow.facility);
		auto contentTypeID = ecu->getOutput().getTypeID();
		NCDBInvType* type = [self.databaseManagedObjectContext invTypeWithTypeID:row.pin.typeID];
		NCDBInvType* contentType = contentTypeID ? [self.databaseManagedObjectContext invTypeWithTypeID:contentTypeID] : nil;

		if (extractorRow.bars.count > 0) {
			NCExtractorCell* cell = (NCExtractorCell*) tableViewCell;
			cell.titleLabel.attributedText = title;
			cell.object = type;
			
			[cell.barChartView clear];
			[cell.barChartView addSegments:extractorRow.bars];

			cell.productLabel.text = contentType.typeName ?: NSLocalizedString(@"Not Routed", nil);
			
			cell.axisYLabel.text = [NSNumberFormatter neocomLocalizedStringFromInteger:extractorRow.maxProduct];
			
			cell.cycleTimeLabel.text = toString(ecu->getCycleTime());
			
			uint32_t sum = extractorRow.allTimeYield + extractorRow.allTimeWaste;
			NSTimeInterval duration = ecu->getExpiryTime() - ecu->getInstallTime();
			cell.sumLabel.text = [NSNumberFormatter neocomLocalizedStringFromInteger:sum];
			cell.yieldLabel.text = duration > 0 ? [NSNumberFormatter neocomLocalizedStringFromNumber:@(sum / (duration / 3600))] : @"0";

			if (extractorRow.currentState && extractorRow.currentState->getCurrentCycle()) {
				NSTimeInterval remainsTime = ecu->getExpiryTime() - serverTimestamp;
				
				cell.markerLabel.text = NSLocalizedString(@"Now", nil);
				if (remainsTime > 0) {
//					cell.axisXLabel.text = remainsTime > 0 ? [NSString stringWithTimeLeft:remainsTime componentsLimit:3] : NSLocalizedString(@"Finished", nil);
					cell.expiredLabel.text = [NSString stringWithTimeLeft:remainsTime componentsLimit:3];
					cell.expiredLabel.textColor = remainsTime > 3600 * 24 ? [UIColor greenColor] : [UIColor yellowColor];
					auto cycle = extractorRow.currentState->getCurrentCycle();
					int32_t cycleTime = cycle->getCycleTime();
					int32_t start = cycle->getLaunchTime();
					int32_t currentTime = [serverTime timeIntervalSinceReferenceDate];
					int32_t c = std::max(std::min(static_cast<int32_t>(currentTime), start + cycleTime), start) - start;
					cell.currentCycleLabel.text = toString(c);

				}
				else {
//					cell.axisXLabel.text = nil;
					cell.currentCycleLabel.text = toString(0);
					cell.expiredLabel.text = toString(0);
					cell.expiredLabel.textColor = [UIColor redColor];
				}

			}
			else {
//				cell.axisXLabel.text = nil;
				cell.currentCycleLabel.text = toString(0);
				cell.expiredLabel.text = toString(0);
				cell.expiredLabel.textColor = [UIColor redColor];
			}
			
			
			duration = [row.endDate timeIntervalSinceDate:row.startDate];
			NSTimeInterval time = [serverTime timeIntervalSinceDate:row.startDate];
			float multiplier = time <= 0 || duration <= 0 ? 0 : time / duration;
			[cell.markerAuxiliaryView.superview removeConstraint:cell.markerAuxiliaryViewConstraint];
			NSLayoutConstraint* constraint = [NSLayoutConstraint constraintWithItem:cell.markerAuxiliaryView
																		  attribute:NSLayoutAttributeWidth
																		  relatedBy:NSLayoutRelationEqual
																			 toItem:cell.barChartView
																		  attribute:NSLayoutAttributeWidth
																		 multiplier:std::max(std::min(multiplier, 1.0f), 0.0f)
																		   constant:0];
			cell.markerAuxiliaryViewConstraint = constraint;
			[cell.markerAuxiliaryView.superview addConstraint:constraint];
			
			if (time < duration) {
				cell.axisXLabel.text = [NSString stringWithTimeLeft:duration - time componentsLimit:3];
				cell.markerLabel.text = NSLocalizedString(@"Now", nil);
			}
			else {
				cell.axisXLabel.text = NSLocalizedString(@"Finished", nil);
				cell.markerLabel.text = nil;
			}

			
			
			if (extractorRow.nextWasteState || extractorRow.allTimeWaste > 0) {
				NSTimeInterval after = extractorRow.nextWasteState ? extractorRow.nextWasteState->getTimestamp() - [serverTime timeIntervalSinceReferenceDate] : 0;
				if (after > 0) {
					cell.wasteTimeLabel.text = [NSString stringWithTimeLeft:after];
					cell.wasteTitleLabel.text = NSLocalizedString(@"Waste in", nil);
					cell.wasteLabel.text = [NSString stringWithFormat:NSLocalizedString(@"(%.0f%%)", nil),
											static_cast<double>(extractorRow.allTimeWaste) / (extractorRow.allTimeWaste + extractorRow.allTimeYield) * 100];
				}
				else {
					cell.wasteTitleLabel.text = NSLocalizedString(@"Waste", nil);
					cell.wasteLabel.text = nil;
					cell.wasteTimeLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%.0f%%", nil),
											static_cast<double>(extractorRow.allTimeWaste) / (extractorRow.allTimeWaste + extractorRow.allTimeYield) * 100];
				}
			}
			else {
				cell.wasteLabel.text = nil;
				cell.wasteTimeLabel.text = nil;
				cell.wasteTitleLabel.text = nil;
			}
		}
		else {
			NCDefaultTableViewCell* cell = (NCDefaultTableViewCell*) tableViewCell;
			cell.object = type;
			cell.titleLabel.attributedText = title;
			cell.iconView.image = type.icon ? type.icon.image.image : [self.databaseManagedObjectContext defaultTypeIcon].image.image;
			cell.subtitleLabel.text = nil;
		}
	}
	else if ([row isKindOfClass:[NCPlanetaryViewControllerStorageRow class]]) {
		NCPlanetaryViewControllerStorageRow* storageRow = (NCPlanetaryViewControllerStorageRow*) row;
		
		auto storage = std::dynamic_pointer_cast<const dgmpp::StorageFacility>(storageRow.facility);
		NCDBInvType* type = [self.databaseManagedObjectContext invTypeWithTypeID:row.pin.typeID];
		
		if (storageRow.currentState) {
			NCStorageCell* cell = (NCStorageCell*) tableViewCell;
			cell.titleLabel.attributedText = title;
			cell.object = type;
			
			[cell.barChartView clear];
			[cell.barChartView addSegments:storageRow.bars];
			
			for (UIView* view in [[cell.materialsView subviews] copy])
				[view removeFromSuperview];

			double capacity = storage->getCapacity();
			if (capacity > 0) {
				double volume = 0;
				
				std::list<const dgmpp::Commodity> commodities;
				
				if (storageRow.currentState) {
					volume = storageRow.currentState->getVolume();
					std::copy(storageRow.currentState->getCommodities().begin(), storageRow.currentState->getCommodities().end(), std::inserter(commodities, commodities.begin()));
					cell.markerLabel.text = NSLocalizedString(@"Now", nil);
				}
				else {
					volume = storage->getVolume();
					commodities = storage->getCommodities();
					cell.markerLabel.text = nil;
				}
				
				NSMutableArray* components = [NSMutableArray new];
				for (const auto& commodity: commodities) {
					NCDBInvType* type = [self.databaseManagedObjectContext invTypeWithTypeID:commodity.getTypeID()];
					if (type.typeName)
						[components addObject:@{@"typeName":type.typeName, @"quantity":@(commodity.getQuantity())}];
				}
				[components sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"typeName" ascending:YES]]];
				NSMutableArray* titles = [NSMutableArray new];
				NSMutableArray* values = [NSMutableArray new];
				NSMutableArray* units = [NSMutableArray new];
				UIFont* font = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];

				UILabel* prevTitle;
				UILabel* prevValue;
				UILabel* prevUnit;
				for (NSDictionary* component in components) {
					UILabel* title = [[UILabel alloc] initWithFrame:CGRectZero];
					title.font = font;
					title.textColor = [UIColor lightTextColor];
					title.textAlignment = NSTextAlignmentLeft;
					title.translatesAutoresizingMaskIntoConstraints = NO;
					[title setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
					[title setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
					title.text = component[@"typeName"];
					[titles addObject:title];
					[cell.materialsView addSubview:title];
					
					UILabel* value = [[UILabel alloc] initWithFrame:CGRectZero];
					value.font = font;
					value.textColor = [UIColor whiteColor];
					value.textAlignment = NSTextAlignmentRight;
					value.translatesAutoresizingMaskIntoConstraints = NO;
					[value setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
					[value setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
					value.text = [NSNumberFormatter neocomLocalizedStringFromInteger:[component[@"quantity"] integerValue]];
					[values addObject:value];
					[cell.materialsView addSubview:value];

					UILabel* unit = [[UILabel alloc] initWithFrame:CGRectZero];
					unit.font = font;
					unit.textColor = [UIColor lightTextColor];
					unit.textAlignment = NSTextAlignmentLeft;
					unit.translatesAutoresizingMaskIntoConstraints = NO;
					[unit setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
					[unit setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
					unit.text = NSLocalizedString(@"units", nil);
					[units addObject:unit];
					[cell.materialsView addSubview:unit];
					
					NSDictionary* bindings = NSDictionaryOfVariableBindings(title, value, unit);
					[cell.materialsView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-15-[title]->=10-[value]-[unit]-15-|" options:0 metrics:nil views:bindings]];

					if (prevTitle) {
						[cell.materialsView addConstraint:[NSLayoutConstraint constraintWithItem:title attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:prevTitle attribute:NSLayoutAttributeBottom multiplier:1 constant:0]];
						[cell.materialsView addConstraint:[NSLayoutConstraint constraintWithItem:value attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:prevValue attribute:NSLayoutAttributeBottom multiplier:1 constant:0]];
						[cell.materialsView addConstraint:[NSLayoutConstraint constraintWithItem:unit attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:prevUnit attribute:NSLayoutAttributeBottom multiplier:1 constant:0]];
						
						[cell.materialsView addConstraint:[NSLayoutConstraint constraintWithItem:title attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:prevTitle attribute:NSLayoutAttributeWidth multiplier:1 constant:0]];
						[cell.materialsView addConstraint:[NSLayoutConstraint constraintWithItem:value attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:prevValue attribute:NSLayoutAttributeWidth multiplier:1 constant:0]];
						[cell.materialsView addConstraint:[NSLayoutConstraint constraintWithItem:unit attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:prevUnit attribute:NSLayoutAttributeWidth multiplier:1 constant:0]];
					}
					else {
						[cell.materialsView addConstraint:[NSLayoutConstraint constraintWithItem:title attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:cell.materialsView attribute:NSLayoutAttributeTop multiplier:1 constant:0]];
						[cell.materialsView addConstraint:[NSLayoutConstraint constraintWithItem:value attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:cell.materialsView attribute:NSLayoutAttributeTop multiplier:1 constant:0]];
						[cell.materialsView addConstraint:[NSLayoutConstraint constraintWithItem:unit attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:cell.materialsView attribute:NSLayoutAttributeTop multiplier:1 constant:0]];
					}
					prevTitle = title;
					prevValue = value;
					prevUnit = unit;
				}
				if (prevTitle) {
					[cell.materialsView addConstraint:[NSLayoutConstraint constraintWithItem:prevTitle attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:cell.materialsView attribute:NSLayoutAttributeBottom multiplier:1 constant:0]];
					[cell.materialsView addConstraint:[NSLayoutConstraint constraintWithItem:prevValue attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:cell.materialsView attribute:NSLayoutAttributeBottom multiplier:1 constant:0]];
					[cell.materialsView addConstraint:[NSLayoutConstraint constraintWithItem:prevUnit attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:cell.materialsView attribute:NSLayoutAttributeBottom multiplier:1 constant:0]];
				}
			}
			else {
			}
			
			NSTimeInterval remainsTime = [row.endDate timeIntervalSinceDate:serverTime];;
			cell.axisXLabel.text = remainsTime > 0 ? [NSString stringWithTimeLeft:remainsTime componentsLimit:3] : NSLocalizedString(@"Finished", nil);
			
			
			NSTimeInterval duration = [row.endDate timeIntervalSinceDate:row.startDate];
			NSTimeInterval time = [serverTime timeIntervalSinceDate:row.startDate];
			float multiplier = time <= 0 || duration <= 0 ? 0 : time / duration;
			[cell.markerAuxiliaryView.superview removeConstraint:cell.markerAuxiliaryViewConstraint];
			NSLayoutConstraint* constraint = [NSLayoutConstraint constraintWithItem:cell.markerAuxiliaryView
																		  attribute:NSLayoutAttributeWidth
																		  relatedBy:NSLayoutRelationEqual
																			 toItem:cell.barChartView
																		  attribute:NSLayoutAttributeWidth
																		 multiplier:std::max(std::min(multiplier, 1.0f), 0.0f)
																		   constant:0];
			cell.markerAuxiliaryViewConstraint = constraint;
			[cell.markerAuxiliaryView.superview addConstraint:constraint];
			
		}
		else {
			NCDefaultTableViewCell* cell = (NCDefaultTableViewCell*) tableViewCell;
			cell.object = type;
			cell.titleLabel.attributedText = title;
			cell.iconView.image = type.icon ? type.icon.image.image : [self.databaseManagedObjectContext defaultTypeIcon].image.image;
			cell.subtitleLabel.text = nil;
		}
	}
	else if ([row isKindOfClass:[NCPlanetaryViewControllerFactoryRow class]]) {
		NCPlanetaryViewControllerFactoryRow* factoryRow = (NCPlanetaryViewControllerFactoryRow*) row;
		NCDBInvType* type = [self.databaseManagedObjectContext invTypeWithTypeID:row.pin.typeID];
		NCDBInvType* productType = [self.databaseManagedObjectContext invTypeWithTypeID:factoryRow.factories.front()->getOutput().getTypeID()];

		NCFactoryCell* cell = (NCFactoryCell*) tableViewCell;
		
		cell.object = type;
		if (factoryRow.factories.size() > 1)
			cell.titleLabel.attributedText = [NSAttributedString attributedStringWithHTMLString:[NSString stringWithFormat:@"<color=white>%ldx</color> %@", factoryRow.factories.size(), row.pin.typeName]];
		else
			cell.titleLabel.attributedText = title;
		
		cell.factoryIconView.image = type.icon.image.image ?: [self.databaseManagedObjectContext defaultTypeIcon].image.image;
		cell.productLabel.text = productType.typeName ?: NSLocalizedString(@"Unknown Type", nil);
		
		cell.effectivityLabel.text = [NSString stringWithFormat:@"%.0f%%", factoryRow.productionTime + factoryRow.idleTime > 0 ? factoryRow.productionTime / (factoryRow.productionTime + factoryRow.idleTime) * 100 : 0.0];
		cell.extrapolatedEffectivityLabel.text = [NSString stringWithFormat:@"%.0f%%", factoryRow.extrapolatedProductionTime + factoryRow.extrapolatedIdleTime > 0 ? factoryRow.extrapolatedProductionTime / (factoryRow.extrapolatedProductionTime + factoryRow.extrapolatedIdleTime) * 100 : 0.0];
		
		NSMutableArray* requiredResources = [NSMutableArray new];

		if (factoryRow.lastState) {
			auto factory = factoryRow.factories.front();
			for (const auto& i: factory->getSchematic()->getInputs()) {
				bool depleted = true;
				for (const auto& j: factoryRow.lastState->getCommodities()) {
					if (i.getTypeID() == j.getTypeID()) {
						if (i.getQuantity() == j.getQuantity())
							depleted = false;
						break;
					}
				}
				
				NCDBInvType* type = [self.databaseManagedObjectContext invTypeWithTypeID:i.getTypeID()];
				
				[requiredResources addObject:@{@"name":type.typeName ?: NSLocalizedString(@"Unknown", nil),
											   @"depleted":@(depleted),
											   @"typeID":@(i.getTypeID())}];
			}
		}
		[requiredResources sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]]];
		NSArray* labels = @[cell.input1TitleLabel, cell.input2TitleLabel, cell.input3TitleLabel];
		NSArray* shortageLabels = @[cell.input1ShortageLabel, cell.input2ShortageLabel, cell.input3ShortageLabel];
		NSArray* ratioLabels = @[cell.input1RatioLabel, cell.input2RatioLabel, cell.input3RatioLabel];
		
		int i = 0;
		
		double p = 0;
		for (const auto& i: factoryRow.ratio) {
			if (i.second > 0)
				p = std::max(p, 1.0 / i.second);
		}
		
		for (NSDictionary* dic in requiredResources) {
			UILabel* label = labels[i];
			UILabel* shortageLabel = shortageLabels[i];
			UILabel* ratioLabel = ratioLabels[i];
			label.text = dic[@"name"];
			if ([dic[@"depleted"] boolValue]) {
				NSString* text;
				double shortage = factoryRow.lastState->getTimestamp() - serverTimestamp;
				if (shortage <= 0)
					text = NSLocalizedString(@"<color=red>depleted</color>", nil);
				else
					text = [NSString stringWithFormat:NSLocalizedString(@"shortage in <color=%@>%@</color>", nil), shortage > 3600 * 24 ? @"green" : @"yellow", [NSString stringWithTimeLeft:shortage]];
				shortageLabel.attributedText = [NSAttributedString attributedStringWithHTMLString:text];
			}
			else
				shortageLabel.text = nil;
			
			if (factoryRow.ratio.size() > 1) {
				double c = std::round(factoryRow.ratio[[dic[@"typeID"] intValue]] * p * 10) / 10;
				if (c == 0)
					ratioLabel.text = @"0  ";
				else if (c == 1)
					ratioLabel.text = @"1  ";
				else
					ratioLabel.text = [NSString stringWithFormat:@"%.1f  ", c];
			}
			else
				ratioLabel.text = nil;
			i++;
		}
		
		for (; i < 3; i++) {
			UILabel* label = labels[i];
			UILabel* shortageLabel = shortageLabels[i];
			UILabel* ratioLabel = ratioLabels[i];
			label.text = nil;
			shortageLabel.text = nil;
			ratioLabel.text = nil;
		}

	}
	else {
		NCDefaultTableViewCell* cell = (NCDefaultTableViewCell*) tableViewCell;
		cell.titleLabel.attributedText = [NSAttributedString attributedStringWithHTMLString:[NSString stringWithFormat:@"<color=lightText>%@</color>", row.pinName]];
		cell.subtitleLabel.text = nil;
		cell.imageView.image = nil;
	}
/*
	if (([row isKindOfClass:[NCPlanetaryViewControllerExtractorRow class]] || [row isKindOfClass:[NCPlanetaryViewControllerStorageRow class]]) && [[row valueForKey:@"bars"] count] > 0) {
		NCPlanetaryCell* cell = (NCPlanetaryCell*) tableViewCell;
		cell.titleLabel.text = row.pin.typeName;
		NCDBInvType* type = [self.databaseManagedObjectContext invTypeWithTypeID:row.pin.typeID];
		cell.object = type;

		[cell.barChartView clear];

		if ([row isKindOfClass:[NCPlanetaryViewControllerExtractorRow class]]) {
			NCPlanetaryViewControllerExtractorRow* extractorRow = (NCPlanetaryViewControllerExtractorRow*) row;
			auto ecu = std::dynamic_pointer_cast<const dgmpp::ExtractorControlUnit>(extractorRow.facility);
			auto contentTypeID = ecu->getOutput().getTypeID();
			NCDBInvType* contentType = contentTypeID ? [self.databaseManagedObjectContext invTypeWithTypeID:contentTypeID] : nil;
			
			//cell.productLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Extracting %@", nil), contentType.typeName];
			cell.productLabel.attributedText = [NSAttributedString attributedStringWithHTMLString:[NSString stringWithFormat:NSLocalizedString(@"Extracting <color=white>%@</color>", nil), contentType.typeName]];

			cell.axisYLabel.text = [NSNumberFormatter neocomLocalizedStringFromInteger:extractorRow.maxProduct];
			[cell.barChartView addSegments:extractorRow.bars];
			if (extractorRow.currentCycle) {
				cell.currentCycleLabel.attributedText = [NSAttributedString attributedStringWithHTMLString:[NSString stringWithFormat:NSLocalizedString(@"Current Cycle <color=white>%@ units</color>", nil), [NSNumberFormatter neocomLocalizedStringFromInteger:extractorRow.currentCycle->getYield().getQuantity() + extractorRow.currentCycle->getWaste().getQuantity()]]];
				int32_t cycleTime = extractorRow.currentCycle->getCycleTime();
				int32_t start = extractorRow.currentCycle->getLaunchTime();
				int32_t currentTime = [serverTime timeIntervalSinceReferenceDate];
				int32_t c = std::max(std::min(static_cast<int32_t>(currentTime), start + cycleTime), start) - start;
				
				NSString* timeString = [NSString stringWithFormat:NSLocalizedString(@"%.2d:%.2d:%.2d / %.2d:%.2d:%.2d", nil), c / 3600, (c % 3600) / 60, c % 60, cycleTime / 3600, (cycleTime % 3600) / 60, cycleTime % 60];
				cell.progressLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%@", nil), timeString];
				cell.progressLabel.progress = static_cast<double>(c) / cycleTime;
				cell.progressLabel.hidden = NO;
			}
			else {
				cell.currentCycleLabel.text = NSLocalizedString(@"Expired", nil);
				cell.progressLabel.text = nil;
				cell.progressLabel.progress = 0;
			}
			
			double sum = extractorRow.allTimeYield + extractorRow.allTimeWaste;
			NSTimeInterval duration = [extractorRow.endDate timeIntervalSinceDate:extractorRow.startDate];
			
			NSMutableAttributedString* statistics = [NSMutableAttributedString new];
			[statistics appendAttributedString:[NSAttributedString attributedStringWithHTMLString:[NSString stringWithFormat:NSLocalizedString(@"Sum <color=white>%@</color>, per hour <color=white>%@</color>", nil),
																								   [NSNumberFormatter neocomLocalizedStringFromInteger:sum],
																								   [NSNumberFormatter neocomLocalizedStringFromInteger:duration > 0 ? sum / (duration / 3600) : 0]]]];
			
			if (extractorRow.nextWasteCycle || extractorRow.allTimeWaste > 0) {
				NSTextAttachment* icon = [NSTextAttachment new];
				icon.image = [self.databaseManagedObjectContext eveIconWithIconFile:@"09_11"].image.image;
				icon.bounds = CGRectMake(0, -9 -cell.warningLabel.font.descender, 18, 18);
				NSMutableAttributedString* s = [statistics mutableCopy];
				[s appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n" attributes:nil]];

				[s appendAttributedString:[NSAttributedString attributedStringWithAttachment:icon]];
				[s appendAttributedString:[[NSAttributedString alloc] initWithString:@" " attributes:nil]];
				NSTimeInterval after = extractorRow.nextWasteCycle ? extractorRow.nextWasteCycle->getLaunchTime() - [serverTime timeIntervalSinceReferenceDate] : 0;
				if (after > 0)
					[s appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:NSLocalizedString(@"Waste in %@", nil), [NSString stringWithTimeLeft:after]]
																			  attributes:nil]];
				else
					[s appendAttributedString:[[NSAttributedString alloc] initWithString:NSLocalizedString(@"Waste", nil)
																			  attributes:nil]];
				[s appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:NSLocalizedString(@" (%.0f%%)", nil), static_cast<double>(extractorRow.allTimeWaste) / (extractorRow.allTimeWaste + extractorRow.allTimeYield) * 100]
																		  attributes:nil]];
				cell.warningLabel.attributedText = s;
			}
			else
				cell.warningLabel.attributedText = statistics;
			
			cell.materialsLabel.text = nil;
		}
		else {
			NCPlanetaryViewControllerStorageRow* storageRow = (NCPlanetaryViewControllerStorageRow*) row;
			auto storage = std::dynamic_pointer_cast<const dgmpp::StorageFacility>(storageRow.facility);
			cell.productLabel.text = nil;
			cell.axisYLabel.text = NSLocalizedString(@"100%", nil);
			[cell.barChartView addSegments:storageRow.bars];
			cell.warningLabel.text = nil;
			
			double capacity = storage->getCapacity();
			
			if (capacity > 0) {
				double volume = 0;
				
				std::list<std::shared_ptr<const dgmpp::Commodity>> commodities;
				
				if (storageRow.currentCycle) {
					volume = storageRow.currentCycle->getVolume();
					commodities = storageRow.currentCycle->getCommodities();
					
				}
				else {
					volume = storage->getVolume();
					commodities = storage->getCommodities();
				}

				
				cell.progressLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%.0f / %.0f m3", nil), volume, capacity];
				cell.progressLabel.progress = volume / capacity;
				cell.progressLabel.hidden = NO;
				
				NSMutableArray* components = [NSMutableArray new];
				for (const auto& commodity: commodities) {
					NCDBInvType* type = [self.databaseManagedObjectContext invTypeWithTypeID:commodity->getTypeID()];
					if (type) {
						[components addObject:[NSString stringWithFormat:NSLocalizedString(@"%@: %@ (%@ m3)", nil), type.typeName, [NSNumberFormatter neocomLocalizedStringFromInteger:commodity->getQuantity()], [NSNumberFormatter neocomLocalizedStringFromNumber:@(commodity->getVolume())]]];
					}
				}
				cell.materialsLabel.text = [components componentsJoinedByString:@"\n"];

			}
			else {
				cell.progressLabel.hidden = YES;
				cell.materialsLabel.text = nil;
			}
			
		}
		
		NSTimeInterval remainsTime = [row.endDate timeIntervalSinceDate:serverTime];;
		cell.axisXLabel.text = remainsTime > 0 ? [NSString stringWithTimeLeft:remainsTime componentsLimit:3] : NSLocalizedString(@"Expired", nil);

		
		NSTimeInterval duration = [row.endDate timeIntervalSinceDate:row.startDate];
		NSTimeInterval time = [serverTime timeIntervalSinceDate:row.startDate];
		float multiplier = time <= 0 || duration <= 0 ? 0 : time / duration;
		[cell.markerAuxiliaryView.superview removeConstraint:cell.markerAuxiliaryViewConstraint];
		NSLayoutConstraint* constraint = [NSLayoutConstraint constraintWithItem:cell.markerAuxiliaryView
																	  attribute:NSLayoutAttributeWidth
																	  relatedBy:NSLayoutRelationEqual
																		 toItem:cell.barChartView
																	  attribute:NSLayoutAttributeWidth
																	 multiplier:std::max(std::min(multiplier, 1.0f), 0.0f)
																	   constant:0];
		cell.markerAuxiliaryViewConstraint = constraint;
		[cell.markerAuxiliaryView.superview addConstraint:constraint];
		
	}
	else if ([row isKindOfClass:[NCPlanetaryViewControllerFactoryRow class]]) {
		NCDefaultTableViewCell* cell = (NCDefaultTableViewCell*) tableViewCell;
		
		NCDBInvType* type = [self.databaseManagedObjectContext invTypeWithTypeID:row.pin.typeID];
		cell.object = type;

		if (type) {
			cell.iconView.image = type.icon ? type.icon.image.image : [self.databaseManagedObjectContext defaultTypeIcon].image.image;
			cell.titleLabel.text = type.typeName;
		}
		else {
			cell.iconView.image = [self.databaseManagedObjectContext unknownTypeIcon].image.image;
			cell.titleLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Unknown type %d", nil), row.pin.typeID];
		}
		
		NCPlanetaryViewControllerIndustryRow* industryRow = (NCPlanetaryViewControllerIndustryRow*) row;
		auto factory = std::dynamic_pointer_cast<const dgmpp::IndustryFacility>(industryRow.facility);
		auto contentTypeID = factory->getOutput().getTypeID();
		NCDBInvType* contentType = contentTypeID ? [self.databaseManagedObjectContext invTypeWithTypeID:contentTypeID] : nil;
		NSString* typeName = contentType ? contentType.typeName : [NSString stringWithFormat:NSLocalizedString(@"Unknown type %d", nil), contentTypeID];
		
		NSMutableAttributedString* s = [[NSMutableAttributedString alloc] initWithAttributedString:[[NSAttributedString alloc] initWithString:typeName attributes:@{NSForegroundColorAttributeName:[UIColor whiteColor]}]];
		[s appendAttributedString:[[NSAttributedString alloc] initWithString:@": " attributes:nil]];
		
		if (factory->getSchematic()) {
			NSTimeInterval time = industryRow.lastProductionCycle ? industryRow.lastProductionCycle->getLaunchTime() - [serverTime timeIntervalSinceReferenceDate] : 0;
			NSMutableArray* requiredResources = [NSMutableArray new];
			for (const auto& input: factory->getSchematic()->getInputs()) {
				int32_t required = input.getQuantity();
				if (industryRow.lastCycle) {
					for (const auto& material: industryRow.lastCycle->getMaterials()) {
						if (material->getTypeID() == input.getTypeID()) {
							required -= material->getQuantity();
							break;
						}
					}
				}
				if (required > 0) {
					NCDBInvType* type = [self.databaseManagedObjectContext invTypeWithTypeID:input.getTypeID()];
					if (type.typeName)
						[requiredResources addObject:type.typeName];
				}
			}
			
			NSString* requiredResourcesString;
			if (requiredResources.count > 0)
				requiredResourcesString = [requiredResources componentsJoinedByString:@" and "];
			else
				requiredResourcesString = NSLocalizedString(@"Resources ", nil);
			
			if (time > 0) {
				[s appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:NSLocalizedString(@"%@ are exhausted in ", nil), requiredResourcesString, [NSString stringWithTimeLeft:time]]
																		  attributes:nil]];
				[s appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithTimeLeft:time]
																		  attributes:@{NSForegroundColorAttributeName:time < 24*60*60 ? [UIColor yellowColor] : [UIColor greenColor]}]];
				if (industryRow.efficiency > 0 || industryRow.extrapolatedEfficiency > 0) {
					[s appendAttributedString:[[NSAttributedString alloc] initWithString:NSLocalizedString(@"\nEfficiency ", nil) attributes:@{NSForegroundColorAttributeName:[UIColor lightTextColor]}]];
					[s appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:NSLocalizedString(@"%.0f%%", nil), industryRow.efficiency * 100] attributes:@{NSForegroundColorAttributeName:[UIColor whiteColor]}]];
					[s appendAttributedString:[[NSAttributedString alloc] initWithString:NSLocalizedString(@", extrapolated  ", nil) attributes:@{NSForegroundColorAttributeName:[UIColor lightTextColor]}]];
					[s appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:NSLocalizedString(@"%.0f%%", nil), industryRow.extrapolatedEfficiency * 100] attributes:@{NSForegroundColorAttributeName:[UIColor whiteColor]}]];
				}
			}
			else {
				if (industryRow.facility->routed())
					[s appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:NSLocalizedString(@"%@ are exhausted", nil), requiredResourcesString]
																		  attributes:@{NSForegroundColorAttributeName:[UIColor redColor]}]];
				else {
					[s appendAttributedString:[[NSAttributedString alloc] initWithString:NSLocalizedString(@"Not routed", nil) attributes:@{NSForegroundColorAttributeName:[UIColor redColor]}]];
				}
			}
		}
		else {
			[s appendAttributedString:[[NSAttributedString alloc] initWithString:NSLocalizedString(@"Facility not properly configured", nil) attributes:@{NSForegroundColorAttributeName:[UIColor redColor]}]];
		}
		cell.subtitleLabel.attributedText = s;
	}
	else {
		NCDefaultTableViewCell* cell = (NCDefaultTableViewCell*) tableViewCell;
		
		NCDBInvType* type = [self.databaseManagedObjectContext invTypeWithTypeID:row.pin.typeID];
		cell.object = type;
		
		if (type) {
			cell.iconView.image = type.icon ? type.icon.image.image : [self.databaseManagedObjectContext defaultTypeIcon].image.image;
			cell.titleLabel.text = type.typeName;
		}
		else {
			cell.iconView.image = [self.databaseManagedObjectContext unknownTypeIcon].image.image;
			cell.titleLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Unknown type %d", nil), row.pin.typeID];
		}
		cell.subtitleLabel.text = nil;
	}*/
}

- (NSAttributedString*) tableView:(UITableView *)tableView attributedTitleForHeaderInSection:(NSInteger)sectionIndex {
	//NCPlanetaryViewControllerData* data = self.cacheData;
	//NCPlanetaryViewControllerDataColony* colony = data.colonies[sectionIndex];
	NCPlanetaryViewControllerSection* section = self.sections[sectionIndex];
	
	NSMutableAttributedString* title = [NSMutableAttributedString new];
	if (section.warning) {
		NSTextAttachment* icon = [NSTextAttachment new];
		icon.image = [self.databaseManagedObjectContext eveIconWithIconFile:@"09_11"].image.image;
		UIFont* font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
		icon.bounds = CGRectMake(0, -8 -font.descender, 18, 18);
		
		[title appendAttributedString:[NSAttributedString attributedStringWithAttachment:icon]];
		[title appendAttributedString:[[NSAttributedString alloc] initWithString:@" " attributes:nil]];
	}
	[title appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%.1f", section.colony.security] attributes:@{NSForegroundColorAttributeName:[UIColor colorWithSecurity:section.colony.security]}]];
	[title appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@" %@ / %@", section.colony.colony.planetName, section.colony.colony.planetTypeName] attributes:nil]];
	return title;
}

/*- (NSString*) tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)sectionIndex {
	NCPlanetaryViewControllerSection* section = self.sections[sectionIndex];
	return section.rows.count == 0 ? NSLocalizedString(@"Colony production has halted", nil) : nil;
}*/

- (id) identifierForSection:(NSInteger)sectionIndex {
	NCPlanetaryViewControllerSection* section = self.sections[sectionIndex];
	return @(section.colony.colony.planetID);
}

#pragma mark - Private

- (void) setAccount:(NCAccount *)account {
	_account = account;
	[account.managedObjectContext performBlock:^{
		NSString* uuid = account.uuid;
		dispatch_async(dispatch_get_main_queue(), ^{
			self.cacheRecordID = [NSString stringWithFormat:@"%@.%@", NSStringFromClass(self.class), uuid];
		});
	}];
}

@end