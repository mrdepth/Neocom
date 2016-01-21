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
#import "NSString+Neocom.h"
#import "NSNumberFormatter+Neocom.h"

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
@end

@interface NCPlanetaryViewControllerRow : NSObject
@property (nonatomic, strong) EVEPlanetaryPinsItem* pin;

@property (nonatomic, assign) std::shared_ptr<const dgmpp::Facility> facility;
@property (nonatomic, strong) NSDate* startDate;
@property (nonatomic, strong) NSDate* endDate;
@property (nonatomic, assign) int32_t order;
@end

@interface NCPlanetaryViewControllerExtractorRow : NCPlanetaryViewControllerRow
@property (nonatomic, strong) NSArray* bars;
@property (nonatomic, assign) std::shared_ptr<const dgmpp::ProductionCycle> currentCycle;
@property (nonatomic, assign) std::shared_ptr<const dgmpp::ProductionCycle> nextWasteCycle;
@property (nonatomic, assign) uint32_t allTimeYield;
@property (nonatomic, assign) uint32_t allTimeWaste;

@end

@interface NCPlanetaryViewControllerStorageRow : NCPlanetaryViewControllerRow
@property (nonatomic, assign) std::shared_ptr<const dgmpp::StorageCycle> currentCycle;
@property (nonatomic, strong) NSArray* bars;
@end

@interface NCPlanetaryViewControllerIndustryRow : NCPlanetaryViewControllerRow
@property (nonatomic, assign) std::shared_ptr<const dgmpp::ProductionCycle> currentCycle;
@property (nonatomic, assign) std::shared_ptr<const dgmpp::ProductionCycle> firstProductionCycle;
@property (nonatomic, assign) std::shared_ptr<const dgmpp::ProductionCycle> lastProductionCycle;
@property (nonatomic, assign) std::shared_ptr<const dgmpp::ProductionCycle> lastCycle;
@property (nonatomic, assign) std::shared_ptr<const dgmpp::ProductionCycle> nextWasteCycle;
@property (nonatomic, assign) uint32_t allTimeYield;
@property (nonatomic, assign) uint32_t allTimeWaste;
@property (nonatomic, assign) double efficiency;
@property (nonatomic, assign) double extrapolatedEfficiency;
@end


@implementation NCPlanetaryViewControllerSection
@end

@implementation NCPlanetaryViewControllerRow
@end

@implementation NCPlanetaryViewControllerExtractorRow
@end

@implementation NCPlanetaryViewControllerStorageRow
@end

@implementation NCPlanetaryViewControllerIndustryRow
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
	[self performSegueWithIdentifier:@"NCDatabaseTypeInfoViewController" sender:[tableView cellForRowAtIndexPath:indexPath]];
}

#pragma mark - NCTableViewController

- (void) loadCacheData:(id)cacheData withCompletionBlock:(void (^)())completionBlock {
	NCPlanetaryViewControllerData* data = cacheData;
	self.backgrountText = data.colonies.count > 0 ? nil : NSLocalizedString(@"No Results", nil);
	
	self.engine = [NCFittingEngine new];
	[self.engine performBlock:^{
		NSMutableArray* sections = [NSMutableArray new];
		UIColor* green = [UIColor colorWithRed:0 green:0.6 blue:0 alpha:1];
		UIColor* red = [UIColor colorWithRed:0.8 green:0 blue:0 alpha:1];

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
					planet->addRoute(source, destination, route.contentTypeID, route.routeID);
			}
			planet->setLastUpdate(lastUpdateDate ? [lastUpdateDate timeIntervalSinceReferenceDate] : [colony.colony.lastUpdate timeIntervalSinceReferenceDate]);
			planet->simulate();
			
			//Process simulation results
			NCPlanetaryViewControllerSection* section = [NCPlanetaryViewControllerSection new];
			section.colony = colony;
			
			NSMutableArray* rows = [NSMutableArray new];
			for (const auto& facility: planet->getFacilities()) {
				size_t numberOfCycles = facility->numberOfCycles();
				
				EVEPlanetaryPinsItem* pin =  [[colony.pins.pins filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"pinID == %qi", facility->getIdentifier()]] lastObject];

				switch (facility->getGroupID()) {
					case dgmpp::ExtractorControlUnit::GROUP_ID: {
						NSMutableArray* segments = [NSMutableArray new];
						NCPlanetaryViewControllerExtractorRow* row = [NCPlanetaryViewControllerExtractorRow new];
						row.facility = facility;
						auto ecu = std::dynamic_pointer_cast<dgmpp::ExtractorControlUnit>(facility);

						double startTime = ecu->getInstallTime();
						double cycleTime = ecu->getCycleTime();

						if (numberOfCycles > 0) {
							uint32_t allTimeYield = 0;
							uint32_t allTimeWaste = 0;

							auto firstCycle = ecu->getCycles().front();
							double maxH = 0;
							for(double time = startTime; time < firstCycle->getLaunchTime(); time += cycleTime) {
								double yield = ecu->getYieldAtTime(time);
								NCBarChartSegment* segment = [NCBarChartSegment new];
								segment.color0 = green;
								segment.color1 = red;
								
								segment.x = time;
								segment.w = cycleTime;
								
								segment.h0 = yield;
								segment.h1 = 0;
								maxH = std::max(yield, maxH);
								[segments addObject:segment];
							}

							std::shared_ptr<const dgmpp::ProductionCycle> lastCycle;
							std::shared_ptr<const dgmpp::ProductionCycle> firstWasteCycle;
							for (const auto& cycle: ecu->getCycles()) {
								auto ecuCycle = std::dynamic_pointer_cast<const dgmpp::ProductionCycle>(cycle);
								auto yield = ecuCycle->getYield().getQuantity();
								auto waste = ecuCycle->getWaste().getQuantity();
								auto launchTime = ecuCycle->getLaunchTime();
								auto cycleTime = ecuCycle->getCycleTime();
								auto endTime = launchTime + cycleTime;
								
								NCBarChartSegment* segment = [NCBarChartSegment new];
								segment.color0 = green;
								segment.color1 = red;
								segment.x = launchTime;
								segment.w = cycleTime;
								segment.h0 = yield;
								segment.h1 = waste;
								maxH = std::max(segment.h0 + segment.h1, maxH);
								[segments addObject:segment];
								
								if (waste > 0 && !firstWasteCycle && endTime > serverTime)
									firstWasteCycle = ecuCycle;
								
								if (serverTime >= launchTime && serverTime < endTime)
									row.currentCycle = ecuCycle;
								
								allTimeYield += yield;
								allTimeWaste += waste;
								
								lastCycle = ecuCycle;
							}

							if (maxH > 0) {
								for (NCBarChartSegment* segment in segments) {
									segment.h0 /= maxH;
									segment.h1 /= maxH;
								}
							}
							
							row.nextWasteCycle = firstWasteCycle;
							row.allTimeYield = allTimeYield;
							row.allTimeWaste = allTimeWaste;
							row.startDate = [NSDate dateWithTimeIntervalSinceReferenceDate:startTime];
							if (lastCycle)
								row.endDate = [NSDate dateWithTimeIntervalSinceReferenceDate:lastCycle->getLaunchTime() + lastCycle->getCycleTime()];
							else
								row.endDate = row.startDate;
							NSTimeInterval duration = [row.endDate timeIntervalSinceDate:row.startDate];
							if (duration > 0) {
								for (NCBarChartSegment* segment in segments) {
									segment.x = (segment.x - startTime) / duration;
									segment.w /= duration;
								}
							}
							row.bars = segments;
						}
						row.pin = pin;
						row.order = 0;
						[rows addObject:row];
						break;
					}
					case dgmpp::IndustryFacility::GROUP_ID: {
						NCPlanetaryViewControllerIndustryRow* row = [NCPlanetaryViewControllerIndustryRow new];
						row.facility = facility;
						auto factory = std::dynamic_pointer_cast<dgmpp::IndustryFacility>(facility);
						
						if (numberOfCycles > 0) {
							uint32_t allTimeYield = 0;
							uint32_t allTimeWaste = 0;
							NSTimeInterval allTimeProduction = 0;
							NSTimeInterval allTimeIdle = 0;
							NSTimeInterval productionTime = 0;
							NSTimeInterval idleTime = 0;

							std::shared_ptr<const dgmpp::ProductionCycle> firstCycle;
							std::shared_ptr<const dgmpp::ProductionCycle> lastCycle;
							std::shared_ptr<const dgmpp::ProductionCycle> firstProductionCycle;
							std::shared_ptr<const dgmpp::ProductionCycle> lastProductionCycle;
							std::shared_ptr<const dgmpp::ProductionCycle> firstWasteCycle;
							std::shared_ptr<const dgmpp::ProductionCycle> nextProductionCycle;
							
							for (const auto& cycle: factory->getCycles()) {
								auto factoryCycle = std::dynamic_pointer_cast<const dgmpp::ProductionCycle>(cycle);
								auto yield = factoryCycle->getYield().getQuantity();
								auto waste = factoryCycle->getWaste().getQuantity();
								auto launchTime = factoryCycle->getLaunchTime();
								auto cycleTime = factoryCycle->getCycleTime();
								auto endTime = launchTime + cycleTime;
								bool isIdle = factoryCycle->isIdle();
								
								if (!firstCycle)
									firstCycle = factoryCycle;
								if (!firstProductionCycle && !factoryCycle->isIdle())
									firstProductionCycle = factoryCycle;
								
								if (waste > 0 && !firstWasteCycle && endTime > serverTime)
									firstWasteCycle = factoryCycle;
								
								if (serverTime >= launchTime && serverTime < endTime)
									row.currentCycle = factoryCycle;
								if (!nextProductionCycle && serverTime >= launchTime && !isIdle)
									nextProductionCycle = factoryCycle;
								
								allTimeYield += yield;
								allTimeWaste += waste;
								if (firstProductionCycle) {
									if (isIdle)
										allTimeIdle += cycleTime;
									else {
										allTimeProduction += cycleTime;
										lastProductionCycle = factoryCycle;
									}
									if (serverTime > launchTime) {
										if (isIdle)
											idleTime += cycleTime;
										else
											productionTime += cycleTime;
									}
								}
								
								lastCycle = factoryCycle;
							}
							if (firstCycle && lastProductionCycle)
								allTimeIdle = ((lastProductionCycle->getLaunchTime() + lastProductionCycle->getCycleTime()) - firstProductionCycle->getLaunchTime()) - allTimeProduction;
							row.allTimeYield = allTimeYield;
							row.allTimeWaste = allTimeWaste;
							row.efficiency = productionTime > 0 ? productionTime / (productionTime + idleTime) : 0;
							row.extrapolatedEfficiency = allTimeProduction > 0 ? allTimeProduction / (allTimeProduction + allTimeIdle) : 0;
							row.firstProductionCycle = firstProductionCycle;
							row.lastProductionCycle = lastProductionCycle;
							row.nextWasteCycle = firstWasteCycle;
							row.lastCycle = lastCycle;
							
							if (firstCycle)
								row.startDate = [NSDate dateWithTimeIntervalSinceReferenceDate:firstCycle->getLaunchTime()];
							if (lastProductionCycle)
								row.endDate = [NSDate dateWithTimeIntervalSinceReferenceDate:lastProductionCycle->getLaunchTime() + lastProductionCycle->getCycleTime()];
							else
								row.endDate = row.startDate;
						}

						row.order = 2;
						row.pin = pin;
						[rows addObject:row];
						break;
					}
					case dgmpp::StorageFacility::GROUP_ID:
					case dgmpp::Spaceport::GROUP_ID: {
						NSMutableArray* segments = [NSMutableArray new];
						NCPlanetaryViewControllerStorageRow* row = [NCPlanetaryViewControllerStorageRow new];
						row.facility = facility;
						auto storage = std::dynamic_pointer_cast<dgmpp::StorageFacility>(facility);
						
						std::shared_ptr<const dgmpp::StorageCycle> firstCycle;
						std::shared_ptr<const dgmpp::StorageCycle> lastCycle;
						double capacity = storage->getCapacity();
						if (capacity > 0) {
							for (const auto& cycle: storage->getCycles()) {
								auto storageCycle = std::dynamic_pointer_cast<const dgmpp::StorageCycle>(cycle);
								auto launchTime = storageCycle->getLaunchTime();
								auto cycleTime = storageCycle->getCycleTime();
								auto endTime = launchTime + cycleTime;
								
								if (serverTime >= launchTime && serverTime < endTime)
									row.currentCycle = storageCycle;

								NCBarChartSegment* segment = [NCBarChartSegment new];
								segment.color0 = green;
								segment.color1 = red;
								segment.x = launchTime;
								segment.w = cycleTime;
								segment.h0 = storageCycle->getVolume() / capacity;
								[segments addObject:segment];
								
								if (!firstCycle)
									firstCycle = storageCycle;
								lastCycle = storageCycle;
							}
						}

						if (firstCycle)
							row.startDate = [NSDate dateWithTimeIntervalSinceReferenceDate:firstCycle->getLaunchTime()];
						if (lastCycle)
							row.endDate = [NSDate dateWithTimeIntervalSinceReferenceDate:lastCycle->getLaunchTime() + lastCycle->getCycleTime()];
						else
							row.endDate = row.startDate;
						NSTimeInterval duration = [row.endDate timeIntervalSinceDate:row.startDate];
						NSTimeInterval startTime = [row.startDate timeIntervalSinceReferenceDate];
						if (duration > 0) {
							for (NCBarChartSegment* segment in segments) {
								segment.x = (segment.x - startTime) / duration;
								segment.w /= duration;
							}
						}
						row.order = 1;
						row.pin = pin;
						row.bars = segments;
						[rows addObject:row];

						break;
					}
					default:
						break;
				}
			}
			[rows sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"order" ascending:YES], [NSSortDescriptor sortDescriptorWithKey:@"endDate" ascending:YES]]];
			section.rows = rows;
			[sections addObject:section];
		}
		
		dispatch_async(dispatch_get_main_queue(), ^{
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
	if ([row isKindOfClass:[NCPlanetaryViewControllerExtractorRow class]] || [row isKindOfClass:[NCPlanetaryViewControllerStorageRow class]])
		return @"NCPlanetaryCell";
	else
		return @"Cell";
}

- (void) tableView:(UITableView *)tableView configureCell:(UITableViewCell*) tableViewCell forRowAtIndexPath:(NSIndexPath*) indexPath {
	NCPlanetaryViewControllerSection* section = self.sections[indexPath.section];
	NCPlanetaryViewControllerRow* row = section.rows[indexPath.row];
	NSDate* serverTime = [section.colony.pins.eveapi serverTimeWithLocalTime:[NSDate date]];

	if ([row isKindOfClass:[NCPlanetaryViewControllerExtractorRow class]] || [row isKindOfClass:[NCPlanetaryViewControllerStorageRow class]]) {
		NCPlanetaryCell* cell = (NCPlanetaryCell*) tableViewCell;
		cell.titleLabel.text = row.pin.typeName;
		[cell.barChartView clear];

		if ([row isKindOfClass:[NCPlanetaryViewControllerExtractorRow class]]) {
			NCPlanetaryViewControllerExtractorRow* extractorRow = (NCPlanetaryViewControllerExtractorRow*) row;
			auto ecu = std::dynamic_pointer_cast<const dgmpp::ExtractorControlUnit>(extractorRow.facility);
			auto contentTypeID = ecu->getOutput().getTypeID();
			NCDBInvType* contentType = contentTypeID ? [self.databaseManagedObjectContext invTypeWithTypeID:contentTypeID] : nil;
			cell.productLabel.text = contentType.typeName;
			cell.axisYLabel.text = [NSNumberFormatter neocomLocalizedStringFromInteger:ecu->getQuantityPerCycle()];
			[cell.barChartView addSegments:extractorRow.bars];
			if (extractorRow.currentCycle) {
				int32_t cycleTime = extractorRow.currentCycle->getCycleTime();
				int32_t start = extractorRow.currentCycle->getLaunchTime();
				int32_t currentTime = [serverTime timeIntervalSinceReferenceDate];
				int32_t c = std::max(std::min(static_cast<int32_t>(currentTime), start + cycleTime), start) - start;
				
				NSString* timeString = [NSString stringWithFormat:NSLocalizedString(@"%.2d:%.2d:%.2d / %.2d:%.2d:%.2d", nil), c / 3600, (c % 3600) / 60, c % 60, cycleTime / 3600, (cycleTime % 3600) / 60, cycleTime % 60];
				cell.progressLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Production: %@", nil), timeString];
				cell.progressLabel.progress = static_cast<double>(c) / cycleTime;
				cell.progressLabel.hidden = NO;
			}
			else
				cell.progressLabel.hidden = YES;
			
			if (extractorRow.nextWasteCycle || extractorRow.allTimeWaste > 0) {
				NSTextAttachment* icon = [NSTextAttachment new];
				icon.image = [self.databaseManagedObjectContext eveIconWithIconFile:@"09_11"].image.image;
				icon.bounds = CGRectMake(0, -9 -cell.warningLabel.font.descender, 18, 18);
				NSMutableAttributedString* s = [[NSAttributedString attributedStringWithAttachment:icon] mutableCopy];
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
				cell.warningLabel.text = nil;
		}
		else {
			NCPlanetaryViewControllerStorageRow* storageRow = (NCPlanetaryViewControllerStorageRow*) row;
			auto storage = std::dynamic_pointer_cast<const dgmpp::StorageFacility>(storageRow.facility);
			cell.productLabel.text = nil;
			cell.axisYLabel.text = NSLocalizedString(@"100%", nil);
			[cell.barChartView addSegments:storageRow.bars];
			cell.warningLabel.text = nil;
			if (storageRow.currentCycle) {
				double volume = storageRow.currentCycle->getVolume();
				double capacity = storage->getCapacity();
				cell.progressLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%.0f / %.0f m3", nil), volume, capacity];
				cell.progressLabel.progress = volume / capacity;
				cell.progressLabel.hidden = NO;
			}
			else
				cell.progressLabel.hidden = YES;
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
	else if ([row isKindOfClass:[NCPlanetaryViewControllerIndustryRow class]]) {
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
				if (industryRow.efficiency > 0 || industryRow.extrapolatedEfficiency > 0)
					[s appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:NSLocalizedString(@"\nEfficiency %.0f%%, extrapolated %.0f%%", nil), industryRow.efficiency * 100, industryRow.extrapolatedEfficiency * 100]
																			  attributes:nil]];
			}
			else
				[s appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:NSLocalizedString(@"%@ are exhausted", nil), requiredResourcesString]
																		  attributes:@{NSForegroundColorAttributeName:[UIColor redColor]}]];
		}
		else {
			[s appendAttributedString:[[NSAttributedString alloc] initWithString:NSLocalizedString(@"Facility not properly configured", nil) attributes:@{NSForegroundColorAttributeName:[UIColor redColor]}]];
		}
		cell.subtitleLabel.attributedText = s;
	}
}

- (NSAttributedString*) tableView:(UITableView *)tableView attributedTitleForHeaderInSection:(NSInteger)section {
	NCPlanetaryViewControllerData* data = self.cacheData;
	NCPlanetaryViewControllerDataColony* colony = data.colonies[section];
	NSMutableAttributedString* title = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%.1f", colony.security] attributes:@{NSForegroundColorAttributeName:[UIColor colorWithSecurity:colony.security]}];
	[title appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@" %@ / %@", colony.colony.planetName, colony.colony.planetTypeName] attributes:nil]];
	return title;
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