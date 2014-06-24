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
				
				starbase.type = [NCDBInvType invTypeWithTypeID:starbase.typeID];
				starbase.solarSystem = [NCDBMapSolarSystem mapSolarSystemWithSolarSystemID:starbase.locationID];
				starbase.moon = [NCDBMapDenormalize mapDenormalizeWithItemID:starbase.moonID];
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
@property (nonatomic, strong) NCCacheRecord* sovereigntyCacheRecord;
@property (nonatomic, strong) EVESovereignty* sovereignty;
@property (nonatomic, strong) NSDate* currentDate;
@property (nonatomic, strong) NSDateFormatter* dateFormatter;
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
	[self.dateFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_GB"]];
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
	NCStarbasesViewControllerData* data = self.data;
	return data.sections.count;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	NCStarbasesViewControllerData* data = self.data;
	return [[data.sections[section] starbases] count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)sectionIndex {
	NCStarbasesViewControllerData* data = self.data;
	NCStarbasesViewControllerDataSection* section = data.sections[sectionIndex];
	return section.title;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	NCStarbasesCell* cell = (NCStarbasesCell*) [tableView dequeueReusableCellWithIdentifier:@"Cell"];
	[self tableView:tableView configureCell:cell forRowAtIndexPath:indexPath];
	return cell;
}

#pragma mark - Table view delegate

- (CGFloat) tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return 73;
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_6_1)
		return [self tableView:tableView estimatedHeightForRowAtIndexPath:indexPath];
	
	UITableViewCell* cell = [self tableView:tableView offscreenCellWithIdentifier:@"Cell"];
	[self tableView:tableView configureCell:cell forRowAtIndexPath:indexPath];
	
	cell.bounds = CGRectMake(0, 0, CGRectGetWidth(tableView.bounds), CGRectGetHeight(cell.bounds));
	[cell layoutIfNeeded];
	return [cell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height + 1.0;
}

#pragma mark - NCTableViewController

- (void) reloadDataWithCachePolicy:(NSURLRequestCachePolicy) cachePolicy {
	__block NSError* error = nil;
	NCAccount* account = [NCAccount currentAccount];
	if (!account || account.accountType != NCAccountTypeCorporate) {
		[self didFinishLoadData:nil withCacheDate:nil expireDate:nil];
		return;
	}
	
	NCStarbasesViewControllerData* data = [NCStarbasesViewControllerData new];
	__block NSDate* cacheExpireDate = [NSDate dateWithTimeIntervalSinceNow:[self defaultCacheExpireTime]];
	
	[[self taskManager] addTaskWithIndentifier:NCTaskManagerIdentifierAuto
										 title:NCTaskManagerDefaultTitle
										 block:^(NCTask *task) {
											 EVEStarbaseList* starbases = [EVEStarbaseList starbaseListWithKeyID:account.apiKey.keyID
																										   vCode:account.apiKey.vCode
																									 cachePolicy:cachePolicy
																									 characterID:account.characterID
																										   error:&error
																								 progressHandler:^(CGFloat progress, BOOL *stop) {
																									 task.progress = progress / 2.0;
																								 }];
											 
											 if (starbases) {
												 cacheExpireDate = starbases.cacheExpireDate;
												 
												 float i = 0;
												 float n = starbases.starbases.count;
												 NSMutableArray* itemIDs = [NSMutableArray new];
												 for (EVEStarbaseListItem* starbase in starbases.starbases) {
													 if ([task isCancelled])
														 return;
													 
													 starbase.details = [EVEStarbaseDetail starbaseDetailWithKeyID:account.apiKey.keyID
																											 vCode:account.apiKey.vCode
																									   cachePolicy:cachePolicy
																									   characterID:account.characterID
																											itemID:starbase.itemID
																											 error:&error
																								   progressHandler:^(CGFloat progress, BOOL *stop) {
																									   task.progress = 0.5 + (i + progress) / n;
																								   }];
													 
													 starbase.type = [NCDBInvType invTypeWithTypeID:starbase.typeID];
													 starbase.solarSystem = [NCDBMapSolarSystem mapSolarSystemWithSolarSystemID:starbase.locationID];
													 starbase.moon = [NCDBMapDenormalize mapDenormalizeWithItemID:starbase.moonID];

													 if (account.corporationSheet.allianceID) {
														 for (EVESovereigntyItem* sovereignty in self.sovereignty.solarSystems) {
															 if (sovereignty.solarSystemID == starbase.locationID) {
																 if (sovereignty.allianceID == account.corporationSheet.allianceID)
																	 starbase.resourceConsumptionBonus = 0.75;
																 else
																	 starbase.resourceConsumptionBonus = 1.0;
																 break;
															 }
														 }
													 }
													 else
														 starbase.resourceConsumptionBonus = 1.0;
													 [itemIDs addObject:@(starbase.itemID)];
													 i += 1.0;
												 }
												 
												 NSMutableDictionary* titles = [NSMutableDictionary new];
												 EVELocations* eveLocations = [EVELocations locationsWithKeyID:account.apiKey.keyID vCode:account.apiKey.vCode cachePolicy:cachePolicy characterID:account.characterID ids:itemIDs corporate:YES error:nil progressHandler:nil];
												 for (EVELocationsItem* location in eveLocations.locations)
													 titles[@(location.itemID)] = location.itemName;
												 for (EVEStarbaseListItem* starbase in starbases.starbases) {
													 starbase.title = titles[@(starbase.itemID)];
													 if (!starbase.title)
														 starbase.title = starbase.type.typeName;
												 }

												 
												 NSArray* rows = [starbases.starbases sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"solarSystem.solarSystemName" ascending:YES]]];
												 NSMutableArray* sections = [NSMutableArray new];
												 for (NSArray* array in [rows arrayGroupedByKey:@"solarSystem.constellation.region.regionID"]) {
													 NCStarbasesViewControllerDataSection* section = [NCStarbasesViewControllerDataSection new];
													 NCDBMapSolarSystem* solarSystem = [array[0] solarSystem];
													 section.title = solarSystem.constellation.region.regionName;
													 section.starbases = array;
													 [sections addObject:section];
												 }
												 [sections sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"title" ascending:YES]]];
												 data.sections = sections;
												 data.currentTime = starbases.currentTime;
												 data.cacheDate = starbases.cacheDate;
											 }
										 }
							 completionHandler:^(NCTask *task) {
								 if (!task.isCancelled) {
									 if (error) {
										 [self didFailLoadDataWithError:error];
									 }
									 else {
										 [self didFinishLoadData:data withCacheDate:[NSDate date] expireDate:cacheExpireDate];
									 }
								 }
							 }];
}

- (void) update {
	[super update];
	NCStarbasesViewControllerData* data = self.data;
	self.currentDate = [NSDate dateWithTimeInterval:[data.currentTime timeIntervalSinceDate:data.cacheDate] sinceDate:[NSDate date]];
}

- (void) didChangeAccount:(NCAccount *)account {
	[super didChangeAccount:account];
	if ([self isViewLoaded])
		[self reloadFromCache];
}

- (void) tableView:(UITableView *)tableView configureCell:(UITableViewCell*) tableViewCell forRowAtIndexPath:(NSIndexPath*) indexPath {
	NCStarbasesViewControllerData* data = self.data;
	NCStarbasesViewControllerDataSection* section = data.sections[indexPath.section];
	EVEStarbaseListItem* row = section.starbases[indexPath.row];
	
	NCStarbasesCell* cell = (NCStarbasesCell*) tableViewCell;
	cell.object = row;
	cell.typeImageView.image = row.type.icon ? row.type.icon.image.image : [[[NCDBEveIcon defaultTypeIcon] image] image];
	cell.titleLabel.text = row.title;
	
	
	NSString* location = nil;
	if (row.moon && row.solarSystem)
		location = [NSString stringWithFormat:@"%@ / %@", row.solarSystem.solarSystemName, row.moon.itemName];
	else if (row.moon)
		location = [NSString stringWithFormat:@"%@ / %@", row.moon.solarSystem.solarSystemName, row.moon.itemName];
	else if (row.solarSystem)
		location = row.solarSystem.solarSystemName;
	
	float security = 1.0;
	if (location) {
		if (row.solarSystem)
			security = row.solarSystem.security;
		else if (row.moon)
			security = row.moon.security;
		
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
	
	float hours = [[row.details serverTimeWithLocalTime:[NSDate date]] timeIntervalSinceDate:row.details.currentTime] / 3600.0;
	if (hours < 0)
		hours = 0;
	float bonus = row.resourceConsumptionBonus;
	
	int minRemains = INT_MAX;
	int minQuantity = 0;
	NCDBInvControlTowerResource *minResource = nil;
	
	for (NCDBInvControlTowerResource *resource in row.type.controlTower.resources) {
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
		cell.resourceTypeImageView.image = minResource.resourceType.icon ? minResource.resourceType.icon.image.image : [[[NCDBEveIcon defaultTypeIcon] image] image];
	else
		cell.resourceTypeImageView.image = nil;
	cell.fuelLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Fuel: %@", nil), state];
	cell.fuelLabel.textColor = color;
}

#pragma mark - Private

- (NCCacheRecord*) sovereigntyCacheRecord {
	@synchronized(self) {
		if (!_sovereigntyCacheRecord) {
			[[[NCCache sharedCache] managedObjectContext] performBlockAndWait:^{
				_sovereigntyCacheRecord = [NCCacheRecord cacheRecordWithRecordID:@"EVESovereignty"];
			}];
		}
		return _sovereigntyCacheRecord;
	}
}

- (EVESovereignty*) sovereignty {
	@synchronized(self) {
		if (!_sovereignty) {
			_sovereignty = self.sovereigntyCacheRecord.data.data;
			
			if (!_sovereignty || [self.sovereigntyCacheRecord.expireDate compare:[NSDate date]] == NSOrderedAscending) {
				EVESovereignty* sovereignty = [EVESovereignty sovereigntyWithCachePolicy:NSURLRequestUseProtocolCachePolicy error:nil progressHandler:nil];
				if (sovereignty) {
					_sovereignty = sovereignty;
					NCCache* cache = [NCCache sharedCache];
					[cache.managedObjectContext performBlockAndWait:^{
						self.cacheRecord.data.data = sovereignty;
						self.cacheRecord.date = sovereignty.cacheDate;
						self.cacheRecord.expireDate = [sovereignty.cacheExpireDate laterDate:[NSDate dateWithTimeIntervalSinceNow:3600 * 24]];
						[cache saveContext];
					}];
					
				}
			}
		}
		return _sovereignty;
	}
}

@end
