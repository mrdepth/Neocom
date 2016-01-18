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
@property (nonatomic, strong) NSArray* bars;
@property (nonatomic, assign) std::shared_ptr<const dgmpp::Cycle> currentCycle;
@property (nonatomic, strong) EVEPlanetaryPinsItem* pin;
@property (nonatomic, assign) uint32_t quantityPerCycle;
@property (nonatomic, assign) int32_t contentTypeID;
@property (nonatomic, strong) NSDate* startDate;
@property (nonatomic, strong) NSDate* endDate;
@end

@implementation NCPlanetaryViewControllerSection
@end

@implementation NCPlanetaryViewControllerRow
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

#pragma mark - NCTableViewController

- (void) loadCacheData:(id)cacheData withCompletionBlock:(void (^)())completionBlock {
	NCPlanetaryViewControllerData* data = cacheData;
	self.backgrountText = data.colonies.count > 0 ? nil : NSLocalizedString(@"No Results", nil);
	
	NCFittingEngine* engine = [NCFittingEngine new];
	[engine performBlock:^{
		NSMutableArray* sections = [NSMutableArray new];
		for (NCPlanetaryViewControllerDataColony* colony in data.colonies) {
			double serverTime = [[colony.pins.eveapi serverTimeWithLocalTime:[NSDate date]] timeIntervalSinceReferenceDate];
			
			auto planet = engine.engine->setPlanet(colony.colony.planetTypeID);
			NSDate* lastUpdateTime = nil;
			
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
								break;
							}
							default:
								break;
						}
					}
					
					lastUpdateTime = lastUpdateTime ? pin.lastLaunchTime ? [lastUpdateTime laterDate:pin.lastLaunchTime] : lastUpdateTime : pin.lastLaunchTime;
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
			planet->setLastUpdate(lastUpdateTime ? [lastUpdateTime timeIntervalSinceReferenceDate] : [colony.colony.lastUpdate timeIntervalSinceReferenceDate]);
			auto endTime = planet->simulate();
			double startTime = planet->getLastUpdate();
			double duration = endTime - startTime;
			
			NCPlanetaryViewControllerSection* section = [NCPlanetaryViewControllerSection new];
			section.colony = colony;
			UIColor* green = [UIColor greenColor];
			UIColor* red = [UIColor redColor];
			NSMutableArray* rows = [NSMutableArray new];
			for (const auto& facility: planet->getFacilities()) {
				size_t numberOfCycles = facility->numberOfCycles();
				NSMutableArray* segments = [NSMutableArray new];
				NCPlanetaryViewControllerRow* row = [NCPlanetaryViewControllerRow new];
				switch (facility->getGroupID()) {
					case dgmpp::ExtractorControlUnit::GROUP_ID: {
						auto ecu = std::dynamic_pointer_cast<dgmpp::ExtractorControlUnit>(facility);
						double max = 0;
						if (numberOfCycles > 0) {
							double startTime = ecu->getInstallTime();
							double endTime = ecu->getExpiryTime();
							double duration = endTime - startTime;
							double cycleTime = ecu->getCycleTime();
							auto firstCycle = ecu->getCycle(size_t(0));
							for(double time = startTime; time < firstCycle->getLaunchTime(); time += cycleTime) {
								double yield = ecu->getYieldAtTime(time);
								NCBarChartSegment* segment = [NCBarChartSegment new];
								segment.x = (time - startTime) / duration;
								
								segment.w = cycleTime / duration;
								segment.h0 = yield;
								segment.h1 = 0;
								segment.color0 = green;
								segment.color1 = red;
								[segments addObject:segment];
								max = std::max(segment.h0 + segment.h1, max);
							}
							
							for (size_t i = 0; i < numberOfCycles; i++) {
								auto cycle = ecu->getCycle(i);
								NCBarChartSegment* segment = [NCBarChartSegment new];
								segment.x = (cycle->getLaunchTime() - startTime) / duration;
								segment.w = cycle->getCycleTime() / duration;
								segment.h0 = cycle->getYield().getQuantity();
								segment.h1 = cycle->getWaste().getQuantity();
								segment.color0 = green;
								segment.color1 = red;
								[segments addObject:segment];
								max = std::max(segment.h0 + segment.h1, max);
							}
							if (max > 0) {
								for (NCBarChartSegment* segment in segments) {
									segment.h0 /= max;
									segment.h1 /= max;
								}
							}
						}
						row.startDate = [NSDate dateWithTimeIntervalSinceReferenceDate:startTime];
						row.endDate = [NSDate dateWithTimeIntervalSinceReferenceDate:endTime];
						
						row.quantityPerCycle = ecu->getQuantityPerCycle();
						row.contentTypeID = ecu->getOutput().getTypeID();
						[rows addObject:row];
						break;
					}
					case dgmpp::IndustryFacility::GROUP_ID: {
						auto factory = std::dynamic_pointer_cast<dgmpp::IndustryFacility>(facility);
						double sum = 0;
						for (size_t i = 0; i < numberOfCycles; i++) {
							auto cycle = factory->getCycle(i);
							NCBarChartSegment* segment = [NCBarChartSegment new];
							segment.x = (cycle->getLaunchTime() - startTime) / duration;
							segment.w = cycle->getCycleTime() / duration;
							if (sum == 0) {
								sum = cycle->getYield().getQuantity() + cycle->getWaste().getQuantity();
								if (sum == 0)
									sum = 1;
							}
							segment.h0 = cycle->getYield().getQuantity() / sum;
							segment.h1 = cycle->getWaste().getQuantity() / sum;
							
							segment.color0 = green;
							segment.color1 = red;
							[segments addObject:segment];
						}
						row.quantityPerCycle = sum;
						row.contentTypeID = factory->getOutput().getTypeID();
						row.startDate = [NSDate dateWithTimeIntervalSinceReferenceDate:startTime];
						row.endDate = [NSDate dateWithTimeIntervalSinceReferenceDate:endTime];
						[rows addObject:row];
						break;
					}
					case dgmpp::StorageFacility::GROUP_ID:
					case dgmpp::Spaceport::GROUP_ID: {
						auto storage = std::dynamic_pointer_cast<dgmpp::StorageFacility>(facility);
						auto capacity = storage->getCapacity();
						if (capacity == 0)
							break;
						
						for (size_t i = 0; i < numberOfCycles; i++) {
							auto cycle = storage->getCycle(i);
							NCBarChartSegment* segment = [NCBarChartSegment new];
							segment.x = (cycle->getLaunchTime() - startTime) / duration;
							segment.w = cycle->getCycleTime() / duration;
							segment.h0 = cycle->getVolume() / capacity;
							
							segment.color0 = green;
							[segments addObject:segment];
						}
						row.startDate = [NSDate dateWithTimeIntervalSinceReferenceDate:startTime];
						row.endDate = [NSDate dateWithTimeIntervalSinceReferenceDate:endTime];
						[rows addObject:row];
						break;
					}
					default:
						break;
				}
				row.currentCycle = facility->getCycle(serverTime);
				row.bars = segments;
				row.pin = [[colony.pins.pins filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"pinID == %qi", facility->getIdentifier()]] lastObject];
			}
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
	return row.bars.count > 1 ?  @"NCPlanetaryCell" : @"Cell";
}

- (void) tableView:(UITableView *)tableView configureCell:(UITableViewCell*) tableViewCell forRowAtIndexPath:(NSIndexPath*) indexPath {
	NCPlanetaryViewControllerSection* section = self.sections[indexPath.section];
	NCPlanetaryViewControllerRow* row = section.rows[indexPath.row];
	if (row.bars.count > 1) {
		NCPlanetaryCell* cell = (NCPlanetaryCell*) tableViewCell;
		
		cell.titleLabel.text = row.pin.typeName;
		NCDBInvType* type = [self.databaseManagedObjectContext invTypeWithTypeID:row.pin.typeID];
		NCDBInvType* contentType = row.contentTypeID ? [self.databaseManagedObjectContext invTypeWithTypeID:row.contentTypeID] : nil;
		cell.productLabel.text = contentType.typeName;
		
		[cell.barChartView clear];
		[cell.barChartView addSegments:row.bars];
		[cell.markerAuxiliaryView.superview removeConstraint:cell.markerAuxiliaryViewConstraint];
		
		if (type.group.groupID == dgmpp::StorageFacility::GROUP_ID || type.group.groupID == dgmpp::Spaceport::GROUP_ID)
			cell.axisYLabel.text = NSLocalizedString(@"100%", nil);
		else if (row.quantityPerCycle > 0)
			cell.axisYLabel.text = [NSNumberFormatter neocomLocalizedStringFromInteger:row.quantityPerCycle];
		else
			cell.axisYLabel.text = @"";
		NSTimeInterval currentTime = [[NSDate date] timeIntervalSinceReferenceDate];
		NSTimeInterval start = [row.startDate timeIntervalSinceReferenceDate];
		NSTimeInterval end = [row.endDate timeIntervalSinceReferenceDate];
		NSTimeInterval duration = end - start;
		
		NSLayoutConstraint* constraint = [NSLayoutConstraint constraintWithItem:cell.markerAuxiliaryView
																	  attribute:NSLayoutAttributeWidth
																	  relatedBy:NSLayoutRelationEqual
																		 toItem:cell.barChartView
																	  attribute:NSLayoutAttributeWidth
																	 multiplier:(currentTime - start) / duration
																	   constant:0];
		cell.markerAuxiliaryViewConstraint = constraint;
		[cell.markerAuxiliaryView.superview addConstraint:constraint];
	}

/*
	NCDBInvType* type = self.types[@(row.typeID)];
	if (!type) {
		type = [self.databaseManagedObjectContext invTypeWithTypeID:row.typeID];
		if (type)
			self.types[@(row.typeID)] = type;
	}
	
	if (type) {
		cell.iconView.image = type.icon ? type.icon.image.image : self.defaultTypeIcon.image.image;
		cell.titleLabel.text = type.typeName;
	}
	else {
		cell.iconView.image = self.unknownTypeIcon.image.image;
		cell.titleLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Unknown type %d", nil), row.typeID];
	}

	cell.object = type;
	
	NSDate* currentDate = [NSDate dateWithTimeInterval:[colony.currentTime timeIntervalSinceDate:colony.cacheDate] sinceDate:[NSDate date]];
	

	NSTimeInterval remainsTime = [row.expiryTime timeIntervalSinceDate:currentDate];
	if (remainsTime <= 0 || !row.expiryTime) {
		cell.subtitleLabel.text = NSLocalizedString(@"Expired", nil);
		cell.subtitleLabel.textColor = [UIColor redColor];
	}
	else {
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
			cell.subtitleLabel.text = [NSString stringWithFormat:@"Expires: %@ (%@)", [self.dateFormatter stringFromDate:row.expiryTime], [NSString stringWithTimeLeft:remainsTime]];
		else
			cell.subtitleLabel.text = [NSString stringWithFormat:@"Expires: %@\n%@", [self.dateFormatter stringFromDate:row.expiryTime], [NSString stringWithTimeLeft:remainsTime]];

		if (remainsTime < 3600 * 24)
			cell.subtitleLabel.textColor = [UIColor yellowColor];
		else
			cell.subtitleLabel.textColor = [UIColor greenColor];
	}*/

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
