//
//  NCDatabaseTypeMarketInfoViewController.m
//  Neocom
//
//  Created by Артем Шиманский on 17.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCDatabaseTypeMarketInfoViewController.h"
#import "NCDatabaseTypeInfoViewController.h"
#import "EVEDBAPI.h"
#import "EVECentralAPI.h"
#import "NCDatabaseTypeMarketInfoCell.h"
#import "NSNumberFormatter+Neocom.h"
#import "UIColor+Neocom.h"
#import "UIActionSheet+Block.h"

@interface NCDatabaseTypeMarketInfoViewControllerData : NSObject<NSCoding>
@property (nonatomic, strong) NSArray *sellOrdersSections;
@property (nonatomic, strong) NSArray *buyOrdersSections;
@property (nonatomic, strong) NSArray *sellSummary;
@property (nonatomic, strong) NSArray *buySummary;

@end

@interface NCDatabaseTypeMarketInfoViewControllerRow : NSObject<NSCoding>
@property (nonatomic, strong) EVECentralQuickLookOrder* order;
@property (nonatomic, assign) NSInteger jumps;
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
	[aCoder encodeInteger:self.jumps forKey:@"jumps"];
}

- (id) initWithCoder:(NSCoder *)aDecoder {
	if (self = [super init]) {
		self.order = [aDecoder decodeObjectForKey:@"order"];
		self.jumps = [aDecoder decodeIntegerForKey:@"jumps"];
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

@implementation NCDatabaseTypeMarketInfoViewController

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
	self.searchDisplayController.searchResultsTableView.rowHeight = self.tableView.rowHeight;

	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (IBAction)onChangeMode:(id)sender {
	[[UIActionSheet actionSheetWithStyle:UIActionSheetStyleBlackTranslucent
								   title:nil
					   cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
				  destructiveButtonTitle:nil
					   otherButtonTitles:@[NSLocalizedString(@"Summary", nil), NSLocalizedString(@"Sell orders", nil), NSLocalizedString(@"Buy orders", nil)]
						 completionBlock:^(UIActionSheet *actionSheet, NSInteger selectedButtonIndex) {
							 if (selectedButtonIndex != actionSheet.cancelButtonIndex) {
								 if (selectedButtonIndex == 0)
									 self.mode = NCDatabaseTypeMarketInfoViewControllerModeSummary;
								 else if (selectedButtonIndex == 1)
									 self.mode = NCDatabaseTypeMarketInfoViewControllerModeSellOrders;
								 else
									 self.mode = NCDatabaseTypeMarketInfoViewControllerModeBuyOrders;
								 [self.tableView reloadData];
								 [self.searchDisplayController.searchResultsTableView reloadData];
							 }
						 }
							 cancelBlock:nil] showFromRect:[sender bounds] inView:sender animated:YES];
}

- (void) setMode:(NCDatabaseTypeMarketInfoViewControllerMode)mode {
	_mode = mode;
	UIButton* button = (UIButton*) self.navigationItem.titleView;
	if (mode == NCDatabaseTypeMarketInfoViewControllerModeSummary)
		[button setTitle:NSLocalizedString(@"Summary", nil) forState:UIControlStateNormal];
	else if (mode == NCDatabaseTypeMarketInfoViewControllerModeSellOrders)
		[button setTitle:NSLocalizedString(@"Sell orders", nil) forState:UIControlStateNormal];
	else
		[button setTitle:NSLocalizedString(@"Buy orders", nil) forState:UIControlStateNormal];
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	if ([segue.identifier isEqualToString:@"NCDatabaseTypeInfoViewController"]) {
		NCDatabaseTypeInfoViewController* destinationViewController = segue.destinationViewController;
		destinationViewController.type = self.type;
		destinationViewController.navigationItem.rightBarButtonItem = nil;
	}
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	NCDatabaseTypeMarketInfoViewControllerData* data = self.data;
	if (self.mode == NCDatabaseTypeMarketInfoViewControllerModeSummary)
		return 2;
	else if (self.mode == NCDatabaseTypeMarketInfoViewControllerModeSellOrders)
		return tableView == self.tableView ? data.sellOrdersSections.count : self.filteredSellOrdersSections.count;
	else
		return tableView == self.tableView ? data.buyOrdersSections.count : self.filteredBuyOrdersSections.count;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	NCDatabaseTypeMarketInfoViewControllerData* data = self.data;
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
	NCDatabaseTypeMarketInfoViewControllerData* data = self.data;
	if (self.mode == NCDatabaseTypeMarketInfoViewControllerModeSummary)
		return section == 0 ? NSLocalizedString(@"Sell summary", nil) : NSLocalizedString(@"Buy summary", nil);
	else if (self.mode == NCDatabaseTypeMarketInfoViewControllerModeSellOrders)
		return tableView == self.tableView ? [data.sellOrdersSections[section] title] : [self.filteredSellOrdersSections[section] title];
	else
		return tableView == self.tableView ? [data.buyOrdersSections[section] title] : [self.filteredBuyOrdersSections[section] title];
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	NCDatabaseTypeMarketInfoViewControllerData* data = self.data;
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

	static NSString *cellIdentifier = @"NCDatabaseTypeMarketInfoCell";
	
	
	NCDatabaseTypeMarketInfoCell* cell = (NCDatabaseTypeMarketInfoCell*) [self.tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	cell.priceLabel.text = [NSString stringWithFormat:@"%@ ISK", [NSNumberFormatter neocomLocalizedStringFromNumber:@(row.order.price)]];
	cell.qualityLabel.text = [NSString stringWithFormat:@"Qty: %@", [NSNumberFormatter neocomLocalizedStringFromInteger:row.order.volRemain]];
	
	NSString* ss = [NSString stringWithFormat:@"%.1f", row.order.security];
	NSString* s;
	if (row.order.station)
		s = [NSString stringWithFormat:@"%@ %@ / %@", ss, row.order.station.solarSystem.solarSystemName, row.order.region.regionName];
	else
		s = [NSString stringWithFormat:@"%@ %@", ss, row.order.region.regionName];
	
	NSMutableAttributedString* title = [[NSMutableAttributedString alloc] initWithString:s];
	[title addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithSecurity:row.order.security] range:NSMakeRange(0, ss.length)];
	cell.solarSystemlabel.attributedText = title;

	cell.stationLabel.text = row.order.stationName;
	cell.jumpsLabel.text = nil;
	
	int reported = [[NSDate date] timeIntervalSinceDate:row.order.reportedTime] / (3600 * 24);
	if (reported < 0)
		reported = 0;
	cell.dateLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Reported: %dd ago", nil), reported];

	return cell;
}

#pragma mark - NCTableViewController

- (void) reloadDataWithCachePolicy:(NSURLRequestCachePolicy) cachePolicy {
	EVEDBInvType* type = self.type;
	__block NSError* error = nil;
	
	NCDatabaseTypeMarketInfoViewControllerData* data = [NCDatabaseTypeMarketInfoViewControllerData new];
	
	[[self taskManager] addTaskWithIndentifier:NCTaskManagerIdentifierAuto
										 title:NCTaskManagerDefaultTitle
										 block:^(NCTask *task) {
											 EVECentralQuickLook *quickLook = [EVECentralQuickLook quickLookWithTypeID:type.typeID
																											 regionIDs:nil
																											  systemID:0
																												 hours:0
																												  minQ:0
																										   cachePolicy:cachePolicy
																												 error:&error
																									   progressHandler:^(CGFloat progress, BOOL *stop) {
																										   task.progress = progress;
																										   if ([task isCancelled])
																											   *stop = YES;
																									   }];
											 if (quickLook) {
												 if ([task isCancelled])
													 return;
												 
												 NSMutableDictionary *sellOrdersSectionsDic = [NSMutableDictionary new];
												 NSMutableDictionary *buyOrdersSectionsDic = [NSMutableDictionary new];
												 
												 [quickLook.sellOrders sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"price" ascending:YES]]];
												 [quickLook.buyOrders sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"price" ascending:NO]]];
												 
												 for (EVECentralQuickLookOrder *order in quickLook.sellOrders) {
													 NCDatabaseTypeMarketInfoViewControllerSection* section = sellOrdersSectionsDic[@(order.regionID)];
													 if (!section) {
														 EVEDBMapRegion *mapRegion = [EVEDBMapRegion mapRegionWithRegionID:order.regionID error:nil];
														 section = [NCDatabaseTypeMarketInfoViewControllerSection new];
														 section.title = mapRegion.regionName;
														 section.rows = [NSMutableArray new];
														 sellOrdersSectionsDic[@(order.regionID)] = section;
													 }
													 NCDatabaseTypeMarketInfoViewControllerRow* row = [NCDatabaseTypeMarketInfoViewControllerRow new];
													 row.order = order;
													 [(NSMutableArray*) section.rows addObject:row];
												 }
												 
												 if ([task isCancelled])
													 return;

												 for (EVECentralQuickLookOrder *order in quickLook.buyOrders) {
													 NCDatabaseTypeMarketInfoViewControllerSection* section = buyOrdersSectionsDic[@(order.regionID)];
													 if (!section) {
														 EVEDBMapRegion *mapRegion = [EVEDBMapRegion mapRegionWithRegionID:order.regionID error:nil];
														 section = [NCDatabaseTypeMarketInfoViewControllerSection new];
														 section.title = mapRegion.regionName;
														 section.rows = [NSMutableArray new];
														 buyOrdersSectionsDic[@(order.regionID)] = section;
													 }
													 NCDatabaseTypeMarketInfoViewControllerRow* row = [NCDatabaseTypeMarketInfoViewControllerRow new];
													 row.order = order;
													 [(NSMutableArray*) section.rows addObject:row];
												 }
												 
												 if ([task isCancelled])
													 return;

												 data.sellOrdersSections = [[sellOrdersSectionsDic allValues] sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"title" ascending:YES]]];
												 data.buyOrdersSections = [[buyOrdersSectionsDic allValues] sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"title" ascending:YES]]];
												 
												 NSMutableArray* sellOrders = [NSMutableArray new];
												 for (EVECentralQuickLookOrder *order in quickLook.sellOrders) {
													 NCDatabaseTypeMarketInfoViewControllerRow* row = [NCDatabaseTypeMarketInfoViewControllerRow new];
													 row.order = order;
													 [sellOrders addObject:row];
												 }
												 
												 NSMutableArray* buyOrders = [NSMutableArray new];
												 for (EVECentralQuickLookOrder *order in quickLook.buyOrders) {
													 NCDatabaseTypeMarketInfoViewControllerRow* row = [NCDatabaseTypeMarketInfoViewControllerRow new];
													 row.order = order;
													 [buyOrders addObject:row];
												 }

												 data.sellSummary = sellOrders;
												 data.buySummary = buyOrders;
											 }
										 }
							 completionHandler:^(NCTask *task) {
								 if (!task.isCancelled) {
									 if (error) {
										 [self didFailLoadDataWithError:error];
									 }
									 else {
										 [self didFinishLoadData:data withCacheDate:[NSDate date] expireDate:[NSDate dateWithTimeIntervalSinceNow:[self defaultCacheExpireTime]]];
									 }
								 }
							 }];
}

- (void) didChangeAccount:(NCAccount *)account {
	[super didChangeAccount:account];
	if ([self isViewLoaded])
		[self reloadFromCache];
}

- (NSString*) recordID {
	EVEDBInvType* type = self.type;
	return [NSString stringWithFormat:@"NCDatabaseTypeMarketInfoViewController.%d", type.typeID];
	//return [NSString stringWithFormat:@"%@.%d", [super recordID], type.typeID];
}

- (void) searchWithSearchString:(NSString *)searchString {
	NCDatabaseTypeMarketInfoViewControllerData* data = self.data;

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
							 }];
}

@end
