//
//  NCDatabaseTypeMarketInfoViewController.m
//  Neocom
//
//  Created by Артем Шиманский on 17.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCDatabaseTypeMarketInfoViewController.h"
#import "NCDatabaseTypeInfoViewController.h"
#import <EVEAPI/EVEAPI.h>
#import "NCDatabaseTypeMarketInfoCell.h"
#import "NSNumberFormatter+Neocom.h"
#import "UIColor+Neocom.h"
#import "NCSetting.h"
//#import "EVECentralQuickLookOrder+Neocom.h"

@interface NCDatabaseTypeMarketInfoViewControllerData : NSObject<NSCoding>
@property (nonatomic, strong) NSArray *sellOrdersSections;
@property (nonatomic, strong) NSArray *buyOrdersSections;
@property (nonatomic, strong) NSArray *sellSummary;
@property (nonatomic, strong) NSArray *buySummary;

@end

@interface NCDatabaseTypeMarketInfoViewControllerRow : NSObject<NSCoding>
@property (nonatomic, strong) EVECentralQuickLookOrder* order;
@property (nonatomic, assign) int32_t jumps;
@end

@interface NCDatabaseTypeMarketInfoViewControllerSection : NSObject<NSCoding>
@property (nonatomic, strong) NSArray* rows;
@property (nonatomic, copy) NSString* title;
@end

@interface NCDatabaseTypeMarketInfoViewController ()

@property (nonatomic, strong) NSArray *filteredSellOrdersSections;
@property (nonatomic, strong) NSArray *filteredBuyOrdersSections;
@property (nonatomic, strong) NSArray *filteredSellSummary;
@property (nonatomic, strong) NSArray *filteredBuySummary;
@property (nonatomic, strong) NCDBInvType* type;
@property (nonatomic, strong) NSMutableDictionary* stations;
@property (nonatomic, strong) NSMutableDictionary* regions;

@end

@implementation NCDatabaseTypeMarketInfoViewControllerData

#pragma mark - NSCoding

- (void) encodeWithCoder:(NSCoder *)aCoder {
	[aCoder encodeObject:self.sellOrdersSections forKey:@"sellOrdersSections"];
	[aCoder encodeObject:self.buyOrdersSections forKey:@"buyOrdersSections"];
	[aCoder encodeObject:self.sellSummary forKey:@"sellSummary"];
	[aCoder encodeObject:self.buySummary forKey:@"buySummary"];
}

- (id) initWithCoder:(NSCoder *)aDecoder {
	if (self = [super init]) {
		self.sellOrdersSections = [aDecoder decodeObjectForKey:@"sellOrdersSections"];
		self.buyOrdersSections = [aDecoder decodeObjectForKey:@"buyOrdersSections"];
		self.sellSummary = [aDecoder decodeObjectForKey:@"sellSummary"];
		self.buySummary = [aDecoder decodeObjectForKey:@"buySummary"];
	}
	return self;
}

@end

@implementation NCDatabaseTypeMarketInfoViewControllerRow

#pragma mark - NSCoding

- (void) encodeWithCoder:(NSCoder *)aCoder {
	[aCoder encodeObject:self.order forKey:@"order"];
	[aCoder encodeInt32:self.jumps forKey:@"jumps"];
}

- (id) initWithCoder:(NSCoder *)aDecoder {
	if (self = [super init]) {
		self.order = [aDecoder decodeObjectForKey:@"order"];
		self.jumps = [aDecoder decodeInt32ForKey:@"jumps"];
	}
	return self;
}

@end

@implementation NCDatabaseTypeMarketInfoViewControllerSection

#pragma mark - NSCoding

- (void) encodeWithCoder:(NSCoder *)aCoder {
	[aCoder encodeObject:self.rows forKey:@"rows"];
	[aCoder encodeObject:self.title forKey:@"title"];
}

- (id) initWithCoder:(NSCoder *)aDecoder {
	if (self = [super init]) {
		self.rows = [aDecoder decodeObjectForKey:@"rows"];
		self.title = [aDecoder decodeObjectForKey:@"title"];
	}
	return self;
}

@end

@interface NCDatabaseTypeMarketInfoViewController()
@property (nonatomic, strong) NCSetting* modeSetting;

@end

@implementation NCDatabaseTypeMarketInfoViewController

- (void)viewDidLoad
{
	[super viewDidLoad];

	self.type = [self.databaseManagedObjectContext existingObjectWithID:self.typeID error:nil];
	
	self.modeSetting = [self.storageManagedObjectContext settingWithKey:@"NCDatabaseTypeMarketInfoViewController.mode"];
	self.mode = [self.modeSetting.value integerValue];
	self.cacheRecordID = [NSString stringWithFormat:@"NCDatabaseTypeMarketInfoViewController.%d", self.type.typeID];
	
	if (self.navigationController.viewControllers[0] != self)
		self.navigationItem.leftBarButtonItem = nil;
	
    self.tableView.tableHeaderView = nil;
	self.stations = [NSMutableDictionary new];
	self.regions = [NSMutableDictionary new];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (IBAction)onChangeMode:(id)sender {
	UIAlertController* controller = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
	[controller addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Summary", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
		self.mode = NCDatabaseTypeMarketInfoViewControllerModeSummary;
		[self.tableView reloadData];
		self.modeSetting.value = @(self.mode);
	}]];
	[controller addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Sell orders", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
		self.mode = NCDatabaseTypeMarketInfoViewControllerModeSellOrders;
		[self.tableView reloadData];
		self.modeSetting.value = @(self.mode);
	}]];
	[controller addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Buy orders", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
		self.mode = NCDatabaseTypeMarketInfoViewControllerModeBuyOrders;
		[self.tableView reloadData];
		self.modeSetting.value = @(self.mode);
	}]];
	[controller addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
	}]];

	[controller presentViewController:controller animated:YES completion:nil];
}

- (void) setMode:(NCDatabaseTypeMarketInfoViewControllerMode)mode {
	_mode = mode;
	UIButton* button = (UIButton*) self.navigationItem.titleView;
	if (mode == NCDatabaseTypeMarketInfoViewControllerModeSummary)
		[button setTitle:[NSLocalizedString(@"Summary", nil) stringByAppendingString:@" \u25BE"] forState:UIControlStateNormal];
	else if (mode == NCDatabaseTypeMarketInfoViewControllerModeSellOrders)
		[button setTitle:[NSLocalizedString(@"Sell orders", nil) stringByAppendingString:@" \u25BE"] forState:UIControlStateNormal];
	else
		[button setTitle:[NSLocalizedString(@"Buy orders", nil) stringByAppendingString:@" \u25BE"] forState:UIControlStateNormal];
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

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	NCDatabaseTypeMarketInfoViewControllerData* data = self.cacheData;
	if (self.mode == NCDatabaseTypeMarketInfoViewControllerModeSummary)
		return 2;
	else if (self.mode == NCDatabaseTypeMarketInfoViewControllerModeSellOrders)
		return tableView == self.tableView ? data.sellOrdersSections.count : self.filteredSellOrdersSections.count;
	else
		return tableView == self.tableView ? data.buyOrdersSections.count : self.filteredBuyOrdersSections.count;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	NCDatabaseTypeMarketInfoViewControllerData* data = self.cacheData;
	NSInteger numberOfRows = 0;

	if (self.mode == NCDatabaseTypeMarketInfoViewControllerModeSummary) {
		if (section == 0)
			numberOfRows = tableView == self.tableView ? data.sellSummary.count : self.filteredSellSummary.count;
		else
			numberOfRows = tableView == self.tableView ? data.buySummary.count : self.filteredBuySummary.count;
	}
	else if (self.mode == NCDatabaseTypeMarketInfoViewControllerModeSellOrders)
		numberOfRows = tableView == self.tableView ? [data.sellOrdersSections[section] rows].count : [self.filteredSellOrdersSections[section] rows].count;
	else
		numberOfRows = tableView == self.tableView ? [data.buyOrdersSections[section] rows].count : [self.filteredBuyOrdersSections[section] rows].count;
	
	return MIN(numberOfRows, 30);
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	NCDatabaseTypeMarketInfoViewControllerData* data = self.cacheData;
	if (self.mode == NCDatabaseTypeMarketInfoViewControllerModeSummary)
		return section == 0 ? NSLocalizedString(@"Sell summary", nil) : NSLocalizedString(@"Buy summary", nil);
	else if (self.mode == NCDatabaseTypeMarketInfoViewControllerModeSellOrders)
		return tableView == self.tableView ? [data.sellOrdersSections[section] title] : [self.filteredSellOrdersSections[section] title];
	else
		return tableView == self.tableView ? [data.buyOrdersSections[section] title] : [self.filteredBuyOrdersSections[section] title];
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - NCTableViewController

- (void) downloadDataWithCachePolicy:(NSURLRequestCachePolicy)cachePolicy completionBlock:(void (^)(NSError *))completionBlock {
	__block NSError* lastError = nil;
	
	NSProgress* progress = [NSProgress progressWithTotalUnitCount:5];
	EVECentralAPI* api = [[EVECentralAPI alloc] initWithCachePolicy:cachePolicy];
	
	[api quickLookWithTypeID:self.type.typeID regionIDs:nil systemID:0 hours:0 minQ:0 completionBlock:^(EVECentralQuickLook *quickLook, NSError *error) {
		progress.completedUnitCount++;
		
		NSManagedObjectContext* databaseManagedObjectContext = [[NCDatabase sharedDatabase] createManagedObjectContext];
		[databaseManagedObjectContext performBlock:^{
			NCDatabaseTypeMarketInfoViewControllerData* data = [NCDatabaseTypeMarketInfoViewControllerData new];

			NSMutableDictionary *sellOrdersSectionsDic = [NSMutableDictionary new];
			NSMutableDictionary *buyOrdersSectionsDic = [NSMutableDictionary new];

			NSArray* sellOrders = [quickLook.sellOrders sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"price" ascending:YES]]];
			NSArray* buyOrders = [quickLook.buyOrders sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"price" ascending:YES]]];
			progress.completedUnitCount++;

			for (EVECentralQuickLookOrder *order in sellOrders) {
				NCDatabaseTypeMarketInfoViewControllerSection* section = sellOrdersSectionsDic[@(order.regionID)];
				if (!section) {
					NCDBMapRegion *mapRegion = [databaseManagedObjectContext mapRegionWithRegionID:order.regionID];
					section = [NCDatabaseTypeMarketInfoViewControllerSection new];
					section.title = mapRegion.regionName;
					section.rows = [NSMutableArray new];
					sellOrdersSectionsDic[@(order.regionID)] = section;
				}
				NCDatabaseTypeMarketInfoViewControllerRow* row = [NCDatabaseTypeMarketInfoViewControllerRow new];
				row.order = order;
				[(NSMutableArray*) section.rows addObject:row];
			}
			progress.completedUnitCount++;

			for (EVECentralQuickLookOrder *order in buyOrders) {
				NCDatabaseTypeMarketInfoViewControllerSection* section = buyOrdersSectionsDic[@(order.regionID)];
				if (!section) {
					NCDBMapRegion *mapRegion = [databaseManagedObjectContext mapRegionWithRegionID:order.regionID];
					section = [NCDatabaseTypeMarketInfoViewControllerSection new];
					section.title = mapRegion.regionName;
					section.rows = [NSMutableArray new];
					buyOrdersSectionsDic[@(order.regionID)] = section;
				}
				NCDatabaseTypeMarketInfoViewControllerRow* row = [NCDatabaseTypeMarketInfoViewControllerRow new];
				row.order = order;
				[(NSMutableArray*) section.rows addObject:row];
			}
			progress.completedUnitCount++;

			
			data.sellOrdersSections = [[sellOrdersSectionsDic allValues] sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"title" ascending:YES]]];
			data.buyOrdersSections = [[buyOrdersSectionsDic allValues] sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"title" ascending:YES]]];
			
			NSMutableArray* sell = [NSMutableArray new];
			for (EVECentralQuickLookOrder *order in quickLook.sellOrders) {
				NCDatabaseTypeMarketInfoViewControllerRow* row = [NCDatabaseTypeMarketInfoViewControllerRow new];
				row.order = order;
				[sell addObject:row];
			}
			
			NSMutableArray* buy = [NSMutableArray new];
			for (EVECentralQuickLookOrder *order in quickLook.buyOrders) {
				NCDatabaseTypeMarketInfoViewControllerRow* row = [NCDatabaseTypeMarketInfoViewControllerRow new];
				row.order = order;
				[buy addObject:row];
			}
			
			data.sellSummary = sell;
			data.buySummary = buy;

			dispatch_async(dispatch_get_main_queue(), ^{
				[self saveCacheData:data cacheDate:[NSDate date] expireDate:[NSDate dateWithTimeIntervalSinceNow:NCCacheDefaultExpireTime]];
				completionBlock(lastError);
				progress.completedUnitCount++;
			});
			
		}];
	} progressBlock:nil];
}

- (void) searchWithSearchString:(NSString *)searchString completionBlock:(void (^)())completionBlock {
	completionBlock();
/*	NCDatabaseTypeMarketInfoViewControllerData* data = self.cacheData;

	NSMutableArray *filteredSellOrdersSections = [NSMutableArray new];
	NSMutableArray *filteredBuyOrdersSections = [NSMutableArray new];
	NSMutableArray *filteredSellSummary = [NSMutableArray new];
	NSMutableArray *filteredBuySummary = [NSMutableArray new];
	
	[[self taskManager] addTaskWithIndentifier:NCTaskManagerIdentifierAuto
										 title:nil
										 block:^(NCTask *task) {
											 for (NCDatabaseTypeMarketInfoViewControllerSection* item in data.sellOrdersSections) {
												 NSMutableArray *rows = [NSMutableArray array];
												 if ([item.title rangeOfString:searchString options:NSCaseInsensitiveSearch].location != NSNotFound) {
													 [rows addObjectsFromArray:item.rows];
												 }
												 else {
													 for (NCDatabaseTypeMarketInfoViewControllerRow* row in item.rows) {
														 if ([row.order.stationName rangeOfString:searchString options:NSCaseInsensitiveSearch].location != NSNotFound) {
															 [rows addObject:row];
														 }
													 }
												 }
												 if (rows.count > 0) {
													 NCDatabaseTypeMarketInfoViewControllerSection* section = [NCDatabaseTypeMarketInfoViewControllerSection new];
													 section.title = item.title;
													 section.rows = rows;
													 [filteredSellOrdersSections addObject:section];
												 }
											 }
											 if ([task isCancelled])
												 return;
											 task.progress = 0.25;
											 
											 for (NCDatabaseTypeMarketInfoViewControllerSection* item in data.buyOrdersSections) {
												 NSMutableArray *rows = [NSMutableArray array];
												 if ([item.title rangeOfString:searchString options:NSCaseInsensitiveSearch].location != NSNotFound) {
													 [rows addObjectsFromArray:item.rows];
												 }
												 else {
													 for (NCDatabaseTypeMarketInfoViewControllerRow* row in item.rows) {
														 if ([row.order.stationName rangeOfString:searchString options:NSCaseInsensitiveSearch].location != NSNotFound) {
															 [rows addObject:row];
														 }
													 }
												 }
												 if (rows.count > 0) {
													 NCDatabaseTypeMarketInfoViewControllerSection* section = [NCDatabaseTypeMarketInfoViewControllerSection new];
													 section.title = item.title;
													 section.rows = rows;
													 [filteredBuyOrdersSections addObject:section];
												 }
											 }
											 
											 if ([task isCancelled])
												 return;
											 task.progress = 0.5;
											 
											 for (NCDatabaseTypeMarketInfoViewControllerRow* row in data.sellSummary) {
												 if ([row.order.stationName rangeOfString:searchString options:NSCaseInsensitiveSearch].location != NSNotFound ||
													 (row.order.region && [row.order.region.regionName rangeOfString:searchString options:NSCaseInsensitiveSearch].location != NSNotFound)) {
													 [filteredSellSummary addObject:row];
												 }
											 }
											 if ([task isCancelled])
												 return;
											 task.progress = 0.75;
											 
											 for (NCDatabaseTypeMarketInfoViewControllerRow* row in data.buySummary) {
												 if ([row.order.stationName rangeOfString:searchString options:NSCaseInsensitiveSearch].location != NSNotFound ||
													 (row.order.region && [row.order.region.regionName rangeOfString:searchString options:NSCaseInsensitiveSearch].location != NSNotFound)) {
													 [filteredBuySummary addObject:row];
												 }
											 }
										 }
							 completionHandler:^(NCTask *task) {
								 if (![task isCancelled]) {
									 self.filteredSellOrdersSections = filteredSellOrdersSections;
									 self.filteredBuyOrdersSections = filteredBuyOrdersSections;
									 self.filteredSellSummary = filteredSellSummary;
									 self.filteredBuySummary = filteredBuySummary;
                                     
                                     [self.searchDisplayController.searchResultsTableView reloadData];
								 }
							 }];*/
}

- (id) identifierForSection:(NSInteger)section {
	NCDatabaseTypeMarketInfoViewControllerData* data = self.cacheData;
	if (self.mode == NCDatabaseTypeMarketInfoViewControllerModeSummary)
		return @(section);
	else if (self.mode == NCDatabaseTypeMarketInfoViewControllerModeSellOrders)
		return [data.sellOrdersSections[section] title];
	else
		return [data.buyOrdersSections[section] title];
}

- (NSString*) tableView:(UITableView *)tableView cellIdentifierForRowAtIndexPath:(NSIndexPath *)indexPath {
	return @"Cell";
}

// Customize the appearance of table view cells.
- (void)tableView:(UITableView *)tableView configureCell:(UITableViewCell *)tableViewCell forRowAtIndexPath:(NSIndexPath *)indexPath {
	NCDatabaseTypeMarketInfoViewControllerData* data = self.cacheData;
	NCDatabaseTypeMarketInfoViewControllerRow* row;
	
	if (self.mode == NCDatabaseTypeMarketInfoViewControllerModeSummary) {
		if (indexPath.section == 0)
			row = tableView == self.tableView ? data.sellSummary[indexPath.row] : self.filteredSellSummary[indexPath.row];
		else
			row = tableView == self.tableView ? data.buySummary[indexPath.row] : self.filteredBuySummary[indexPath.row];;
	}
	else if (self.mode == NCDatabaseTypeMarketInfoViewControllerModeSellOrders)
		row = tableView == self.tableView ? [data.sellOrdersSections[indexPath.section] rows][indexPath.row] : [self.filteredSellOrdersSections[indexPath.section] rows][indexPath.row];
	else
		row = tableView == self.tableView ? [data.buyOrdersSections[indexPath.section] rows][indexPath.row] : [self.filteredBuyOrdersSections[indexPath.section] rows][indexPath.row];
	
	
	NCDatabaseTypeMarketInfoCell* cell = (NCDatabaseTypeMarketInfoCell*) tableViewCell;
	cell.priceLabel.text = [NSString stringWithFormat:@"%@ ISK", [NSNumberFormatter neocomLocalizedStringFromNumber:@(row.order.price)]];
	cell.quantityLabel.text = [NSString stringWithFormat:@"Qty: %@", [NSNumberFormatter neocomLocalizedStringFromInteger:row.order.volRemain]];
	
	NSString* ss = [NSString stringWithFormat:@"%.1f", row.order.security];
	NSString* s;
	
	NCDBStaStation* station = self.stations[@(row.order.stationID)];
	if (!station) {
		station = [self.databaseManagedObjectContext staStationWithStationID:row.order.stationID];
		if (station)
			self.stations[@(row.order.stationID)] = station;
	}
	NCDBMapRegion* region = self.regions[@(row.order.regionID)];
	if (!region) {
		region = [self.databaseManagedObjectContext mapRegionWithRegionID:row.order.regionID];
		if (region)
			self.regions[@(row.order.stationID)] = station;
	}

	if (station)
		s = [NSString stringWithFormat:@"%@ %@ / %@", ss, station.solarSystem.solarSystemName, region.regionName];
	else
		s = [NSString stringWithFormat:@"%@ %@", ss, region.regionName];
	
	NSMutableAttributedString* title = [[NSMutableAttributedString alloc] initWithString:s];
	[title addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithSecurity:row.order.security] range:NSMakeRange(0, ss.length)];
	cell.solarSystemlabel.attributedText = title;
	
	cell.stationLabel.text = row.order.stationName;
	cell.jumpsLabel.text = nil;
	
	int32_t reported = [[NSDate date] timeIntervalSinceDate:row.order.reportedTime] / (3600 * 24);
	if (reported < 0)
		reported = 0;
	cell.dateLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Reported: %dd ago", nil), reported];
}

@end
