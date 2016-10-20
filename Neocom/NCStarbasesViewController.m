//
//  NCStarbasesViewController.m
//  Neocom
//
//  Created by Артем Шиманский on 21.02.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCStarbasesViewController.h"
#import "EVEStarbaseListItem+Neocom.h"
#import "NSArray+Neocom.h"
#import "NCStarbasesCell.h"
#import "NSString+Neocom.h"
#import "NSNumberFormatter+Neocom.h"
#import "UIColor+Neocom.h"
#import "NCStarbasesDetailsViewController.h"

@interface NCStarbasesViewControllerDataSection : NSObject<NSCoding>
@property (nonatomic, strong) NSArray* starbases;
@property (nonatomic, strong) NSString* title;
@end

@interface NCStarbasesViewControllerData: NSObject<NSCoding>
@property (nonatomic, strong) NSArray* sections;
@property (nonatomic, strong) NSDate* currentTime;
@property (nonatomic, strong) NSDate* cacheDate;
@end


@implementation NCStarbasesViewControllerDataSection

- (id) initWithCoder:(NSCoder *)aDecoder {
	if (self = [super init]) {
		self.starbases = [aDecoder decodeObjectForKey:@"starbases"];
		self.title = [aDecoder decodeObjectForKey:@"title"];
	}
	return self;
}

- (void) encodeWithCoder:(NSCoder *)aCoder {
	if (self.starbases)
		[aCoder encodeObject:self.starbases forKey:@"starbases"];
	
	if (self.title)
		[aCoder encodeObject:self.title forKey:@"title"];
}

@end

@implementation NCStarbasesViewControllerData

- (id) initWithCoder:(NSCoder *)aDecoder {
	if (self = [super init]) {
		self.sections = [aDecoder decodeObjectForKey:@"sections"];
		self.currentTime = [aDecoder decodeObjectForKey:@"currentTime"];
		self.cacheDate = [aDecoder decodeObjectForKey:@"cacheDate"];
		
		NSDictionary* starbaseDetails = [aDecoder decodeObjectForKey:@"starbaseDetails"];
		for (NCStarbasesViewControllerDataSection* section in self.sections) {
			for (EVEStarbaseListItem* starbase in section.starbases) {
				NSDictionary* details = starbaseDetails[@(starbase.itemID)];
				starbase.details = details[@"details"];
				starbase.resourceConsumptionBonus = [details[@"resourceConsumptionBonus"] floatValue];
				starbase.title = details[@"title"];
			}
		}
	}
	return self;
}

- (void) encodeWithCoder:(NSCoder *)aCoder {
	if (self.sections)
		[aCoder encodeObject:self.sections forKey:@"sections"];
	
	if (self.currentTime)
		[aCoder encodeObject:self.currentTime forKey:@"currentTime"];
	if (self.cacheDate)
		[aCoder encodeObject:self.cacheDate forKey:@"cacheDate"];
	
	NSMutableDictionary* starbaseDetails = [NSMutableDictionary new];
	for (NCStarbasesViewControllerDataSection* section in self.sections) {
		for (EVEStarbaseListItem* starbase in section.starbases) {
			NSMutableDictionary* details = [NSMutableDictionary new];
			if (starbase.details)
				details[@"details"] = starbase.details;
			details[@"resourceConsumptionBonus"] = @(starbase.resourceConsumptionBonus);
			if (starbase.title)
				details[@"title"] = starbase.title;
			starbaseDetails[@(starbase.itemID)] = details;
		}
	}
	[aCoder encodeObject:starbaseDetails forKey:@"starbaseDetails"];
}

@end

@interface NCStarbasesViewController ()
@property (nonatomic, strong) NSDate* currentDate;
@property (nonatomic, strong) NSDateFormatter* dateFormatter;
@property (nonatomic, strong) NSMutableDictionary* types;
@property (nonatomic, strong) NSMutableDictionary* solarSystems;
@property (nonatomic, strong) NSMutableDictionary* moons;
@property (nonatomic, strong) NCDBEveIcon* defaultTypeIcon;
@property (nonatomic, strong) NCDBEveIcon* unknownTypeIcon;
@property (nonatomic, strong) NCAccount* account;

- (void) loadSovereigntyWithCompletionBlock:(void (^)(EVESovereignty* sovereignty))completionBlock;
@end

@implementation NCStarbasesViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	self.dateFormatter = [[NSDateFormatter alloc] init];
	[self.dateFormatter setDateFormat:@"yyyy.MM.dd HH:mm"];
	[self.dateFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"]];
	self.defaultTypeIcon = [self.databaseManagedObjectContext defaultTypeIcon];
	self.unknownTypeIcon = 	[self.databaseManagedObjectContext eveIconWithIconFile:@"74_14"];
	self.types = [NSMutableDictionary new];
	self.solarSystems = [NSMutableDictionary new];
	self.moons = [NSMutableDictionary new];
	self.account = [NCAccount currentAccount];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	if ([segue.identifier isEqualToString:@"NCStarbasesDetailsViewController"]) {
		NCStarbasesDetailsViewController* controller;
		if ([segue.destinationViewController isKindOfClass:[UINavigationController class]])
			controller = [segue.destinationViewController viewControllers][0];
		else
			controller = segue.destinationViewController;
		
		controller.starbase = [sender object];
		controller.currentDate = self.currentDate;
	}
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	NCStarbasesViewControllerData* data = self.cacheData;
	return data.sections.count;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	NCStarbasesViewControllerData* data = self.cacheData;
	return [[data.sections[section] starbases] count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)sectionIndex {
	NCStarbasesViewControllerData* data = self.cacheData;
	NCStarbasesViewControllerDataSection* section = data.sections[sectionIndex];
	return section.title;
}

#pragma mark - NCTableViewController

- (void) downloadDataWithCachePolicy:(NSURLRequestCachePolicy)cachePolicy completionBlock:(void (^)(NSError *))completionBlock {
	__block NSError* lastError = nil;
	NCAccount* account = self.account;
	if (!account) {
		completionBlock(nil);
		return;
	}
	
	NSProgress* progress = [NSProgress progressWithTotalUnitCount:5];
	
	[account.managedObjectContext performBlock:^{
		EVEOnlineAPI* api = [[EVEOnlineAPI alloc] initWithAPIKey:account.eveAPIKey cachePolicy:cachePolicy];
		[account loadCorporationSheetWithCompletionBlock:^(EVECorporationSheet *corporationSheet, NSError *error) {
			if (error)
				lastError = error;
			@synchronized(progress) {
				progress.completedUnitCount++;
			}
			
			[self loadSovereigntyWithCompletionBlock:^(EVESovereignty *sovereignty) {
				@synchronized(progress) {
					progress.completedUnitCount++;
				}
				[api starbaseListWithCompletionBlock:^(EVEStarbaseList *result, NSError *error) {
					NCStarbasesViewControllerData* data = [NCStarbasesViewControllerData new];

					if (error)
						lastError = error;
					progress.completedUnitCount++;
					
					[progress becomeCurrentWithPendingUnitCount:1];
					NSProgress* detailsProgress = [NSProgress progressWithTotalUnitCount:result.starbases.count];
					[progress resignCurrent];
					
					dispatch_group_t finishDispatchGroup = dispatch_group_create();
					
					NSMutableArray* itemIDs = [NSMutableArray new];
					for (EVEStarbaseListItem* starbase in result.starbases) {
						dispatch_group_enter(finishDispatchGroup);
						[api starbaseDetailWithItemID:starbase.itemID completionBlock:^(EVEStarbaseDetail *result, NSError *error) {
							starbase.details = result;
							if (corporationSheet.allianceID) {
								for (EVESovereigntyItem* item in sovereignty.solarSystems) {
									if (item.solarSystemID == starbase.locationID) {
										if (item.allianceID == corporationSheet.allianceID)
											starbase.resourceConsumptionBonus = 0.75;
										else
											starbase.resourceConsumptionBonus = 1.0;
										break;
									}
								}
							}
							else
								starbase.resourceConsumptionBonus = 1.0;
							@synchronized(detailsProgress) {
								detailsProgress.completedUnitCount++;
							}
							dispatch_group_leave(finishDispatchGroup);

						}];
						
						[itemIDs addObject:@(starbase.itemID)];
					}
					
					NSMutableArray* sections = [NSMutableArray new];

					dispatch_group_enter(finishDispatchGroup);
					[api locationsWithIDs:itemIDs completionBlock:^(EVELocations *locations, NSError *error) {
						NSMutableDictionary* titles = [NSMutableDictionary new];
						for (EVELocationsItem* location in locations.locations)
							titles[@(location.itemID)] = location.itemName;
						NSManagedObjectContext* databaseManagedObjectContext = [[NCDatabase sharedDatabase] createManagedObjectContext];
						[databaseManagedObjectContext performBlock:^{
							for (EVEStarbaseListItem* starbase in result.starbases) {
								starbase.title = titles[@(starbase.itemID)];
								if (!starbase.title) {
									NCDBInvType* type = [databaseManagedObjectContext invTypeWithTypeID:starbase.typeID];
									starbase.title = type.typeName ?: [NSString stringWithFormat:@"%d", starbase.typeID];
								}
								starbase.solarSystem = [databaseManagedObjectContext mapSolarSystemWithSolarSystemID:starbase.locationID];
							}
							
							NSArray* rows = [result.starbases sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"solarSystem.solarSystemName" ascending:YES]]];
							for (NSArray* array in [rows arrayGroupedByKey:@"solarSystem.constellation.region.regionID"]) {
								NCStarbasesViewControllerDataSection* section = [NCStarbasesViewControllerDataSection new];
								NCDBMapSolarSystem* solarSystem = [array[0] solarSystem];
								section.title = solarSystem.constellation.region.regionName;
								section.starbases = array;
								[sections addObject:section];
							}
							[sections sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"title" ascending:YES]]];
							[result.starbases setValue:nil forKey:@"solarSystem"];
							@synchronized(progress) {
								progress.completedUnitCount++;
							}
							dispatch_group_leave(finishDispatchGroup);
						}];
																				
					}];

					dispatch_group_notify(finishDispatchGroup, dispatch_get_main_queue(), ^{
						data.sections = sections;
						data.currentTime = result.eveapi.currentTime;
						data.cacheDate = result.eveapi.cacheDate;
						[self saveCacheData:data cacheDate:[NSDate date] expireDate:[result.eveapi localTimeWithServerTime:result.eveapi.cachedUntil]];
						completionBlock(lastError);
					});
				}];
			}];
		}];
	}];
}

- (void) loadCacheData:(id)cacheData withCompletionBlock:(void (^)())completionBlock {
	NCStarbasesViewControllerData* data = cacheData;
	self.currentDate = [NSDate dateWithTimeInterval:[data.currentTime timeIntervalSinceDate:data.cacheDate] sinceDate:[NSDate date]];
	self.backgrountText = data.sections.count > 0 ? nil : NSLocalizedString(@"No Results", nil);

	completionBlock();
}


- (void) didChangeAccount:(NSNotification *)notification {
	[super didChangeAccount:notification];
	self.account = [NCAccount currentAccount];
}

- (NSString*) tableView:(UITableView *)tableView cellIdentifierForRowAtIndexPath:(NSIndexPath *)indexPath {
	return @"Cell";
}

- (void) tableView:(UITableView *)tableView configureCell:(UITableViewCell*) tableViewCell forRowAtIndexPath:(NSIndexPath*) indexPath {
	NCStarbasesViewControllerData* data = self.cacheData;
	NCStarbasesViewControllerDataSection* section = data.sections[indexPath.section];
	EVEStarbaseListItem* row = section.starbases[indexPath.row];
	
	NCStarbasesCell* cell = (NCStarbasesCell*) tableViewCell;
	cell.object = row;
	
	NCDBInvType* type = self.types[@(row.typeID)];
	if (!type) {
		type = [self.databaseManagedObjectContext invTypeWithTypeID:row.typeID];
		if (type)
			self.types[@(row.typeID)] = type;
	}

	
	cell.typeImageView.image = type.icon ? type.icon.image.image : self.defaultTypeIcon.image.image;
	cell.titleLabel.text = row.title;
	
	NCDBMapDenormalize* moon = self.moons[@(row.moonID)];
	if (!moon) {
		moon = [self.databaseManagedObjectContext mapDenormalizeWithItemID:row.moonID];
		if (moon)
			self.moons[@(row.moonID)] = moon;
	}

	NCDBMapSolarSystem* solarSystem = self.solarSystems[@(row.locationID)];
	if (!solarSystem) {
		solarSystem = [self.databaseManagedObjectContext mapSolarSystemWithSolarSystemID:row.locationID];
		if (solarSystem)
			self.solarSystems[@(row.locationID)] = solarSystem;
	}

	NSString* location = nil;
	if (moon && solarSystem)
		location = [NSString stringWithFormat:@"%@ / %@", solarSystem.solarSystemName, moon.itemName];
	else if (moon)
		location = [NSString stringWithFormat:@"%@ / %@", moon.solarSystem.solarSystemName, moon.itemName];
	else if (solarSystem)
		location = row.solarSystem.solarSystemName;
	
	float security = 1.0;
	if (location) {
		if (solarSystem)
			security = solarSystem.security;
		else if (moon)
			security = moon.security;
		
		NSString* ss = [NSString stringWithFormat:@"%.1f", security];
		NSString* s = [NSString stringWithFormat:@"%@ %@", ss, location];
		NSMutableAttributedString* title = [[NSMutableAttributedString alloc] initWithString:s];
		[title addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithSecurity:security] range:NSMakeRange(0, ss.length)];
		cell.locationLabel.attributedText = title;
	}
	else {
		cell.locationLabel.attributedText = nil;
		cell.locationLabel.text = NSLocalizedString(@"Unknown Location", nil);
	}
	
	
	NSString* state = nil;
	UIColor* color = nil;
	switch (row.state) {
		case EVEPOSStateUnanchored:
			state = NSLocalizedString(@"Unanchored", nil);
			color = [UIColor yellowColor];
			break;
		case EVEPOSStateAnchoredOffline:
			state = NSLocalizedString(@"Anchored / Offline", nil);
			color = [UIColor redColor];
			break;
		case EVEPOSStateOnlining: {
			NSTimeInterval remains = [row.onlineTimestamp timeIntervalSinceDate:self.currentDate];
			state = [NSString stringWithFormat:NSLocalizedString(@"Onlining: %@ remains", nil), [NSString stringWithTimeLeft:remains]];
			color = [UIColor yellowColor];
			break;
		}
		case EVEPOSStateReinforced: {
			NSTimeInterval remains = [row.stateTimestamp timeIntervalSinceDate:self.currentDate];
			state = [NSString stringWithFormat:NSLocalizedString(@"Reinforced: %@ remains", nil), [NSString stringWithTimeLeft:remains]];
			color = [UIColor redColor];
			break;
		}
		case EVEPOSStateOnline:
			state = [NSString stringWithFormat:NSLocalizedString(@"Online since %@", nil), [self.dateFormatter stringFromDate:row.onlineTimestamp]];
			color = [UIColor greenColor];
			break;
		default:
			break;
	}
	cell.stateLabel.text = state;
	cell.stateLabel.textColor = color;
	
	float hours = [[row.details.eveapi serverTimeWithLocalTime:[NSDate date]] timeIntervalSinceDate:row.details.eveapi.currentTime] / 3600.0;
	if (hours < 0)
		hours = 0;
	float bonus = row.resourceConsumptionBonus;
	
	int minRemains = INT_MAX;
	int minQuantity = 0;
	NCDBInvControlTowerResource *minResource = nil;
	
	for (NCDBInvControlTowerResource *resource in type.controlTower.resources) {
		if (resource.purpose.purposeID != 1 ||
			(resource.minSecurityLevel > 0 && security < resource.minSecurityLevel) ||
			(resource.factionID > 0 && row.solarSystem.constellation.region.factionID != resource.factionID))
			continue;
		
		int quantity = 0;
		for (EVEStarbaseDetailFuelItem *item in row.details.fuel) {
			if (item.typeID == resource.resourceType.typeID) {
				quantity = item.quantity - hours * round(resource.quantity * bonus);
				break;
			}
		}
		int remains = quantity / round(resource.quantity * bonus) * 3600;
		if (remains < minRemains) {
			minResource = resource;
			minRemains = remains;
			minQuantity = quantity;
		}
	}
	
	if (minQuantity > 0) {
		if (minRemains > 3600 * 24)
			color = [UIColor greenColor];
		else if (minRemains > 3600)
			color = [UIColor yellowColor];
		else
			color = [UIColor redColor];
		state = [NSString stringWithTimeLeft:minRemains];
	}
	else {
		color = [UIColor redColor];
		state = @"0s";
	}
	
	if (minResource)
		cell.resourceTypeImageView.image = minResource.resourceType.icon ? minResource.resourceType.icon.image.image : self.defaultTypeIcon.image.image;
	else
		cell.resourceTypeImageView.image = nil;
	cell.fuelLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Fuel: %@", nil), state];
	cell.fuelLabel.textColor = color;
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

- (void) loadSovereigntyWithCompletionBlock:(void (^)(EVESovereignty* sovereignty))completionBlock {
	NCAccount* account = self.account;
	[account.managedObjectContext performBlock:^{
		EVEOnlineAPI* api = [[EVEOnlineAPI alloc] initWithAPIKey:self.account.eveAPIKey cachePolicy:NSURLRequestUseProtocolCachePolicy];
		
		[self.cacheManagedObjectContext performBlock:^{
			NSString* cacheRecordID = @"EVESovereignty";
			NCCacheRecord* cacheRecord = [self.cacheManagedObjectContext cacheRecordWithRecordID:cacheRecordID];
			__block EVESovereignty* sovereignty = cacheRecord.data.data;
			if (!sovereignty || [cacheRecord isExpired]) {
				[api sovereigntyWithCompletionBlock:^(EVESovereignty *result, NSError *error) {
					if (result) {
						sovereignty = result;
						[self.cacheManagedObjectContext performBlock:^{
							cacheRecord.data.data = result;
							cacheRecord.date = result.eveapi.cacheDate;
							cacheRecord.expireDate = result.eveapi.cachedUntil;
						}];
					}
					completionBlock(sovereignty);
				}];
				
			}
			else {
				completionBlock(sovereignty);
			}
		}];
	}];
}


@end
