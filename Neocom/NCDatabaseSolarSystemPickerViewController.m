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
	
	NCDatabase* database = [NCDatabase sharedDatabase];
	if (!self.rows) {
		if (self.region) {
			NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"MapSolarSystem"];
			request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"solarSystemName" ascending:YES]];
			request.predicate = [NSPredicate predicateWithFormat:@"constellation.region == %@", self.region];
			request.fetchBatchSize = 50;
			self.rows = [database.managedObjectContext executeFetchRequest:request error:nil];
		}
		else {
			NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"MapRegion"];
			request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"regionName" ascending:YES]];
			request.fetchBatchSize = 50;
			self.rows = [database.managedObjectContext executeFetchRequest:request error:nil];
		}
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
	
	UITableViewCell* cell = nil;
	if ([row isKindOfClass:[NCDBMapRegion class]]) {
		cell = [tableView dequeueReusableCellWithIdentifier:@"RegionCell"];
		if (!cell)
			cell = [self.tableView dequeueReusableCellWithIdentifier:@"RegionCell"];
	}
	else {
		cell = [tableView dequeueReusableCellWithIdentifier:@"SolarSystemCell"];
		if (!cell)
			cell = [self.tableView dequeueReusableCellWithIdentifier:@"SolarSystemCell"];
	}
	[self tableView:tableView configureCell:cell forRowAtIndexPath:indexPath];
	return cell;
}

- (NSString*) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	if (tableView == self.tableView)
		return nil;
	else
		return self.searchResults[section][@"title"];
}

#pragma mark - Table view delegate

- (CGFloat) tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return 37;
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	if (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_7_1)
		return UITableViewAutomaticDimension;

	id row;
	if (tableView == self.tableView)
		row = self.rows[indexPath.row];
	else
		row = self.searchResults[indexPath.section][@"rows"][indexPath.row];
	
	UITableViewCell* cell = nil;
	if ([row isKindOfClass:[NCDBMapRegion class]])
		cell = [self tableView:self.tableView offscreenCellWithIdentifier:@"RegionCell"];
	else
		cell = [self tableView:self.tableView offscreenCellWithIdentifier:@"SolarSystemCell"];
	
	[self tableView:tableView configureCell:cell forRowAtIndexPath:indexPath];
	
	cell.bounds = CGRectMake(0, 0, CGRectGetWidth(tableView.bounds), CGRectGetHeight(cell.bounds));
	[cell layoutIfNeeded];
	return [cell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height + 1.0;
}

#pragma mark - NCTableViewController

- (NSString*) recordID {
	return nil;
}

- (void) searchWithSearchString:(NSString*) searchString {
	NSMutableArray* searchResults = [NSMutableArray new];
	
	NCDatabase* database = [NCDatabase sharedDatabase];
	if (self.region) {
		NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"MapSolarSystem"];
		request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"solarSystemName" ascending:YES]];
		request.predicate = [NSPredicate predicateWithFormat:@"constellation.region == %@ AND solarSystemName CONTAINS[C] %@", self.region, searchString];
		request.fetchBatchSize = 50;
		NSArray* solarSystems = [database.managedObjectContext executeFetchRequest:request error:nil];
		if (solarSystems.count > 0)
			[searchResults addObject:@{@"rows": solarSystems}];
	}
	else {
		NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"MapSolarSystem"];
		request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"solarSystemName" ascending:YES]];
		request.predicate = [NSPredicate predicateWithFormat:@"solarSystemName CONTAINS[C] %@", searchString];
		request.fetchBatchSize = 50;
		NSArray* solarSystems = [database.managedObjectContext executeFetchRequest:request error:nil];

		
		request = [NSFetchRequest fetchRequestWithEntityName:@"MapRegion"];
		request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"regionName" ascending:YES]];
		request.predicate = [NSPredicate predicateWithFormat:@"regionName CONTAINS[C] %@", searchString];
		request.fetchBatchSize = 50;
		NSArray* regions = [database.managedObjectContext executeFetchRequest:request error:nil];
		
		if (regions.count > 0)
			[searchResults addObject:@{@"rows": regions, @"title": NSLocalizedString(@"Regions", nil)}];
		if (solarSystems.count > 0)
			[searchResults addObject:@{@"rows": solarSystems, @"title": NSLocalizedString(@"Solar Systems", nil)}];
	}
	self.searchResults = searchResults;
	[self.searchDisplayController.searchResultsTableView reloadData];
}

- (void) tableView:(UITableView *)tableView configureCell:(UITableViewCell*) tableViewCell forRowAtIndexPath:(NSIndexPath*) indexPath {
	id row;
	if (tableView == self.tableView)
		row = self.rows[indexPath.row];
	else
		row = self.searchResults[indexPath.section][@"rows"][indexPath.row];
	
	if ([row isKindOfClass:[NCDBMapRegion class]]) {
		NCDatabaseSolarSystemPickerRegionCell* cell = (NCDatabaseSolarSystemPickerRegionCell*) tableViewCell;
		cell.object = row;
		cell.titleLabel.text = [row regionName];
	}
	else {
		NCTableViewCell* cell = (NCTableViewCell*) tableViewCell;
		cell.object = row;
		cell.titleLabel.text = [row solarSystemName];
	}
}

@end
