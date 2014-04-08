//
//  NCDatabaseSolarSystemPickerViewController.m
//  Neocom
//
//  Created by Артем Шиманский on 27.02.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCDatabaseSolarSystemPickerViewController.h"
#import "NCTableViewCell.h"
#import "NCDatabaseSolarSystemPickerRegionCell.h"

@interface NCDatabaseSolarSystemPickerViewController ()
@property (nonatomic, strong) NSArray* rows;
@property (nonatomic, strong) NSArray* searchResults;
@end

@implementation NCDatabaseSolarSystemPickerViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
	if (self.region)
		self.title = self.region.regionName;
	
	self.refreshControl = nil;
	
	if (!self.rows) {
		NSMutableArray* rows = [NSMutableArray new];
		
		[[self taskManager] addTaskWithIndentifier:NCTaskManagerIdentifierNone
											 title:NCTaskManagerDefaultTitle
											 block:^(NCTask *task) {
												 if (self.region)
													 [[EVEDBDatabase sharedDatabase] execSQLRequest:[NSString stringWithFormat:@"SELECT * FROM mapSolarSystems WHERE regionID=%d ORDER BY solarSystemName;", self.region.regionID]
																						resultBlock:^(sqlite3_stmt *stmt, BOOL *needsMore) {
																							[rows addObject:[[EVEDBMapSolarSystem alloc] initWithStatement:stmt]];
																							if ([task isCancelled])
																								*needsMore = NO;
																						}];
												 else
													 [[EVEDBDatabase sharedDatabase] execSQLRequest:@"SELECT * FROM mapRegions ORDER BY regionName;"
																						resultBlock:^(sqlite3_stmt *stmt, BOOL *needsMore) {
																							[rows addObject:[[EVEDBMapRegion alloc] initWithStatement:stmt]];
																							if ([task isCancelled])
																								*needsMore = NO;
																						}];
											 }
								 completionHandler:^(NCTask *task) {
									 self.rows = rows;
									 [self.tableView reloadData];
								 }];
	}
}

- (void) viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
}

- (void) viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	if ([segue.identifier isEqualToString:@"SolarSystemUnwind"]) {
		self.selectedObject = [sender object];
	}
	else if ([segue.identifier isEqualToString:@"RegionUnwind"]) {
		id cell = [sender superview];
		for (;![cell isKindOfClass:[UITableViewCell class]]; cell = [cell superview]);
		self.selectedObject = [cell object];
	}
	else if ([segue.identifier isEqualToString:@"NCDatabaseSolarSystemPickerViewController"]) {
		NCDatabaseSolarSystemPickerViewController* destinationViewController = segue.destinationViewController;
		destinationViewController.region = [sender object];
	}
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	if (tableView == self.tableView)
		return 1;
	else
		return self.searchResults.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	if (tableView == self.tableView)
		return self.rows.count;
	else
		return [self.searchResults[section][@"rows"] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	id row;
	if (tableView == self.tableView)
		row = self.rows[indexPath.row];
	else
		row = self.searchResults[indexPath.section][@"rows"][indexPath.row];
	
	if ([row isKindOfClass:[EVEDBMapRegion class]]) {
		NCDatabaseSolarSystemPickerRegionCell* cell = [tableView dequeueReusableCellWithIdentifier:@"RegionCell"];
		if (!cell)
			cell = [self.tableView dequeueReusableCellWithIdentifier:@"RegionCell"];
		cell.object = row;
		cell.titleLabel.text = [row regionName];
		return cell;
	}
	else {
		NCTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"SolarSystemCell"];
		if (!cell)
			cell = [self.tableView dequeueReusableCellWithIdentifier:@"SolarSystemCell"];
		cell.object = row;
		cell.titleLabel.text = [row solarSystemName];
		return cell;
	}
}

- (NSString*) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	if (tableView == self.tableView)
		return nil;
	else
		return self.searchResults[section][@"title"];
}

#pragma mark - Table view delegate

- (CGFloat) tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return 41;
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell* cell = [self tableView:tableView cellForRowAtIndexPath:indexPath];
	cell.bounds = CGRectMake(0, 0, CGRectGetWidth(tableView.bounds), CGRectGetHeight(cell.bounds));
	[cell setNeedsLayout];
	[cell layoutIfNeeded];
	return [cell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height + 1.0;
}

#pragma mark - NCTableViewController

- (NSString*) recordID {
	return nil;
}

- (void) searchWithSearchString:(NSString*) searchString {
	NSMutableArray* searchResults = [NSMutableArray new];
	[[self taskManager] addTaskWithIndentifier:NCTaskManagerIdentifierAuto
										 title:nil
										 block:^(NCTask *task) {
											 if ([task isCancelled])
												 return;
											 if (self.region) {
												 NSMutableArray* solarSystems = [NSMutableArray new];
												 [[EVEDBDatabase sharedDatabase] execSQLRequest:[NSString stringWithFormat:@"SELECT * FROM mapSolarSystems WHERE regionID=%d AND solarSystemName LIKE \"%%%@%%\" ORDER BY solarSystemName;", self.region.regionID, searchString]
																					resultBlock:^(sqlite3_stmt *stmt, BOOL *needsMore) {
																						[solarSystems addObject:[[EVEDBMapSolarSystem alloc] initWithStatement:stmt]];
																						if ([task isCancelled])
																							*needsMore = NO;
																					}];
												 if (solarSystems.count > 0)
													 [searchResults addObject:@{@"rows": solarSystems}];
											 }
											 else {
												 NSMutableArray* regions = [NSMutableArray new];
												 [[EVEDBDatabase sharedDatabase] execSQLRequest:[NSString stringWithFormat:@"SELECT * FROM mapRegions WHERE regionName LIKE \"%%%@%%\" ORDER BY regionName;", searchString]
																					resultBlock:^(sqlite3_stmt *stmt, BOOL *needsMore) {
																						[regions addObject:[[EVEDBMapRegion alloc] initWithStatement:stmt]];
																						if ([task isCancelled])
																							*needsMore = NO;
																					}];
												 if (regions.count > 0)
													 [searchResults addObject:@{@"rows": regions, @"title": NSLocalizedString(@"Regions", nil)}];
												 
												 NSMutableArray* solarSystems = [NSMutableArray new];
												 [[EVEDBDatabase sharedDatabase] execSQLRequest:[NSString stringWithFormat:@"SELECT * FROM mapSolarSystems WHERE solarSystemName LIKE \"%%%@%%\" ORDER BY solarSystemName;", searchString]
																					resultBlock:^(sqlite3_stmt *stmt, BOOL *needsMore) {
																						[solarSystems addObject:[[EVEDBMapSolarSystem alloc] initWithStatement:stmt]];
																						if ([task isCancelled])
																							*needsMore = NO;
																					}];
												 if (solarSystems.count > 0)
													 [searchResults addObject:@{@"rows": solarSystems, @"title": NSLocalizedString(@"Solar Systems", nil)}];

											 }
										 }
							 completionHandler:^(NCTask *task) {
								 if (![task isCancelled]) {
									 self.searchResults = searchResults;
									 [self.searchDisplayController.searchResultsTableView reloadData];
								 }
							 }];
}

@end
