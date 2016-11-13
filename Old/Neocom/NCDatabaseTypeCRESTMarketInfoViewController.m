//
//  NCDatabaseTypeCRESTMarketInfoViewController.m
//  Neocom
//
//  Created by Артем Шиманский on 24.12.15.
//  Copyright © 2015 Artem Shimanski. All rights reserved.
//

#import "NCDatabaseTypeCRESTMarketInfoViewController.h"
#import "NCDatabaseTypeInfoViewController.h"
#import "NCSetting.h"
#import <EVEAPI/EVEAPI.h>
#import "NCDatabaseTypeMarketInfoCell.h"
#import "NSNumberFormatter+Neocom.h"
#import "NCDatabaseRegionPickerViewController.h"
#import "UIColor+Neocom.h"
#import "NCLocationsManager.h"

@interface NCDatabaseTypeCRESTMarketInfoViewControllerData : NSObject<NSCoding>
@property (nonatomic, strong) NSArray *sellOrders;
@property (nonatomic, strong) NSArray *buyOrders;
@property (nonatomic, strong) NSDictionary* locations;
@end

@implementation NCDatabaseTypeCRESTMarketInfoViewControllerData

#pragma mark - NSCoding

- (void) encodeWithCoder:(NSCoder *)aCoder {
	[aCoder encodeObject:self.sellOrders forKey:@"sellOrders"];
	[aCoder encodeObject:self.buyOrders forKey:@"buyOrders"];
	[aCoder encodeObject:self.locations forKey:@"locations"];
}

- (id) initWithCoder:(NSCoder *)aDecoder {
	if (self = [super init]) {
		self.sellOrders = [aDecoder decodeObjectForKey:@"sellOrders"];
		self.buyOrders = [aDecoder decodeObjectForKey:@"buyOrders"];
		self.locations = [aDecoder decodeObjectForKey:@"locations"];
	}
	return self;
}

@end


@interface NCDatabaseTypeCRESTMarketInfoViewController()
@property (nonatomic, strong) NCSetting* modeSetting;
@property (nonatomic, strong) NCSetting* regionSetting;
@property (nonatomic, strong) NCDBInvType* type;
@property (nonatomic, strong) NCDBMapRegion* region;
@end

@implementation NCDatabaseTypeCRESTMarketInfoViewController

- (void)viewDidLoad
{
	[super viewDidLoad];
	self.modeSetting = [self.storageManagedObjectContext settingWithKey:@"NCDatabaseTypeCRESTMarketInfoViewController.mode"];
	self.regionSetting = [self.storageManagedObjectContext settingWithKey:@"NCDatabaseTypeCRESTMarketInfoViewController.region"];
	self.mode = [self.modeSetting.value integerValue];
	
	self.type = [self.databaseManagedObjectContext existingObjectWithID:self.typeID error:nil];
	if (self.regionSetting.value)
		self.regionID = [self.databaseManagedObjectContext.persistentStoreCoordinator managedObjectIDForURIRepresentation:self.regionSetting.value];
	
	if (self.regionID)
		self.region = [self.databaseManagedObjectContext existingObjectWithID:self.regionID error:nil];
	if (!self.region)
		self.region = [self.databaseManagedObjectContext mapRegionWithRegionID:10000002]; // The Forge
	
	if (self.navigationController.viewControllers[0] != self)
		self.navigationItem.leftBarButtonItem = nil;

	for (UIViewController* controller in self.navigationController.viewControllers) {
		if ([controller isKindOfClass:[NCDatabaseTypeInfoViewController class]]) {
			id region = self.regionBarButtonItem;
			self.navigationItem.rightBarButtonItems = nil;
			self.navigationItem.rightBarButtonItem = region;
			break;
		}
	}
	
	self.tableView.tableHeaderView = nil;
}

- (IBAction)onChangeMode:(id)sender {
	if ([sender selectedSegmentIndex] == 0)
		self.mode = NCDatabaseTypeCRESTMarketInfoViewControllerModeSell;
	else
		self.mode = NCDatabaseTypeCRESTMarketInfoViewControllerModeBuy;
	[self.tableView reloadData];
}


- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	if ([segue.identifier isEqualToString:@"NCDatabaseTypeInfoViewController"]) {
		NCDatabaseTypeInfoViewController* controller;
		if ([segue.destinationViewController isKindOfClass:[UINavigationController class]])
			controller = [segue.destinationViewController viewControllers][0];
		else
			controller = segue.destinationViewController;
		
		controller.typeID = self.typeID;
		controller.navigationItem.rightBarButtonItem = nil;
	}
}

- (IBAction) unwindFromRegionPicker:(UIStoryboardSegue*)segue {
	NCDatabaseRegionPickerViewController* controller = segue.sourceViewController;
	if (controller.selectedRegion) {
		self.region = [self.databaseManagedObjectContext existingObjectWithID:controller.selectedRegion.objectID error:nil];
		self.regionSetting.value = [self.region.objectID URIRepresentation];
	}
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	NCDatabaseTypeCRESTMarketInfoViewControllerData* data = self.cacheData;
	if (!data)
		return 0;
	else
		return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	NCDatabaseTypeCRESTMarketInfoViewControllerData* data = self.cacheData;
	
	if (self.mode == NCDatabaseTypeCRESTMarketInfoViewControllerModeSell)
		return data.sellOrders.count;
	else
		return data.buyOrders.count;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - NCTableViewController

- (void) downloadDataWithCachePolicy:(NSURLRequestCachePolicy)cachePolicy completionBlock:(void (^)(NSError *))completionBlock {
	__block NSError* lastError = nil;
	
	NSProgress* progress = [NSProgress progressWithTotalUnitCount:3];
	
	NCDatabaseTypeCRESTMarketInfoViewControllerData* data = [NCDatabaseTypeCRESTMarketInfoViewControllerData new];
	dispatch_group_t finishGroup = dispatch_group_create();

	dispatch_group_enter(finishGroup);
	
	[[CRAPI publicApiWithCachePolicy:NSURLRequestUseProtocolCachePolicy] loadSellOrdersWithTypeID:self.type.typeID regionID:self.region.regionID completionBlock:^(CRMarketOrderCollection *marketOrders, NSError *error) {
		if (error)
			lastError = error;
		NSManagedObjectContext* databaseManagedObjectContext = [[NCDatabase sharedDatabase] createManagedObjectContext];
		[databaseManagedObjectContext performBlock:^{
			data.sellOrders = [marketOrders.items sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"price" ascending:YES]]];
			dispatch_group_leave(finishGroup);
			@synchronized(progress) {
				progress.completedUnitCount++;
			}
		}];
	}];
	
	dispatch_group_enter(finishGroup);
	[[CRAPI publicApiWithCachePolicy:NSURLRequestUseProtocolCachePolicy] loadBuyOrdersWithTypeID:self.type.typeID regionID:self.region.regionID completionBlock:^(CRMarketOrderCollection *marketOrders, NSError *error) {
		if (error)
			lastError = error;
		NSManagedObjectContext* databaseManagedObjectContext = [[NCDatabase sharedDatabase] createManagedObjectContext];
		[databaseManagedObjectContext performBlock:^{
			data.buyOrders = [marketOrders.items sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"price" ascending:NO]]];
			dispatch_group_leave(finishGroup);
			@synchronized(progress) {
				progress.completedUnitCount++;
			}
		}];
	}];
	
	dispatch_group_notify(finishGroup, dispatch_get_main_queue(), ^{
		NSMutableArray* locations = [NSMutableArray new];
		[locations addObjectsFromArray:[data.buyOrders valueForKey:@"stationID"]];
		[locations addObjectsFromArray:[data.sellOrders valueForKey:@"stationID"]];
		[[NCLocationsManager defaultManager] requestLocationsNamesWithIDs:locations completionBlock:^(NSDictionary *locationsNames) {
			progress.completedUnitCount++;
			data.locations = locationsNames;
			[self saveCacheData:data cacheDate:[NSDate date] expireDate:[NSDate dateWithTimeIntervalSinceNow:NCCacheDefaultExpireTime]];
			completionBlock(lastError);
		}];
	});
}

- (void) loadCacheData:(id)cacheData withCompletionBlock:(void (^)())completionBlock {
	NCDatabaseTypeCRESTMarketInfoViewControllerData* data = cacheData;
	self.backgrountText = data.sellOrders.count > 0 || data.buyOrders.count > 0 ? nil : NSLocalizedString(@"No Results", nil);
	completionBlock();
}

- (void) searchWithSearchString:(NSString *)searchString completionBlock:(void (^)())completionBlock {
	completionBlock();
}

- (NSString*) tableView:(UITableView *)tableView cellIdentifierForRowAtIndexPath:(NSIndexPath *)indexPath {
	return @"Cell";
}

// Customize the appearance of table view cells.
- (void)tableView:(UITableView *)tableView configureCell:(UITableViewCell *)tableViewCell forRowAtIndexPath:(NSIndexPath *)indexPath {
	NCDatabaseTypeCRESTMarketInfoViewControllerData* data = self.cacheData;
	CRMarketOrder* row;
	if (self.mode == NCDatabaseTypeCRESTMarketInfoViewControllerModeSell)
		row = data.sellOrders[indexPath.row];
	else
		row = data.buyOrders[indexPath.row];
	
	
	NCDatabaseTypeMarketInfoCell* cell = (NCDatabaseTypeMarketInfoCell*) tableViewCell;
	cell.priceLabel.text = [NSString stringWithFormat:@"%@ ISK", [NSNumberFormatter neocomLocalizedStringFromNumber:@(row.price)]];
	cell.quantityLabel.text = [NSString stringWithFormat:@"Qty: %@", [NSNumberFormatter neocomLocalizedStringFromInteger:row.volRemaining]];
	

	NCLocationsManagerItem* item = data.locations[@(row.stationID)];
	if (item) {
		NSMutableAttributedString* title;
		NCDBMapSolarSystem* solarSystem = [self.databaseManagedObjectContext mapSolarSystemWithSolarSystemID:item.solarSystemID];
		if (solarSystem) {
			NSString* ss = [NSString stringWithFormat:@"%.1f", solarSystem.security];
			NSString* s = [NSString stringWithFormat:@"%@ %@ / %@", ss, solarSystem.solarSystemName, solarSystem.constellation.region.regionName];
			title = [[NSMutableAttributedString alloc] initWithString:s];
			[title addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithSecurity:solarSystem.security] range:NSMakeRange(0, ss.length)];
		}
		else {
			title = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:NSLocalizedString(@"Unknown Station %d", nil), row.stationID]];

		}
		cell.solarSystemlabel.attributedText = title;
		cell.stationLabel.text = item.name;
	}
	else {
		NSMutableAttributedString* title;
		NCDBStaStation* station = [self.databaseManagedObjectContext staStationWithStationID:row.stationID];
		if (station) {
			NSString* ss = [NSString stringWithFormat:@"%.1f", station.solarSystem.security];
			NSString* s = [NSString stringWithFormat:@"%@ %@ / %@", ss, station.solarSystem.solarSystemName, station.solarSystem.constellation.region.regionName];
			title = [[NSMutableAttributedString alloc] initWithString:s];
			[title addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithSecurity:station.solarSystem.security] range:NSMakeRange(0, ss.length)];
		}
		else
			title = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:NSLocalizedString(@"Unknown Station %d", nil), row.stationID]];
		cell.solarSystemlabel.attributedText = title;
		cell.stationLabel.text = station.stationName;
	}

	cell.jumpsLabel.text = nil;
	
	int32_t expired = row.duration - [[NSDate date] timeIntervalSinceDate:row.issued] / (3600 * 24);
	if (expired < 0)
		expired = 0;
	cell.dateLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Expired in %@d", nil), @(expired)];
}

- (void) setRegion:(NCDBMapRegion *)region {
	_region = region;
	[self.regionBarButtonItem setTitle:region.regionName ?: NSLocalizedString(@"Region", nil)];
	self.cacheRecordID = [NSString stringWithFormat:@"NCDatabaseTypeCRESTMarketInfoViewController.%d.%d", self.region.regionID, self.type.typeID];
}

@end
