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

- (NSString*) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	if (tableView == self.tableView)
		return nil;
	else
		return self.searchResults[section][@"title"];
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

- (NSString*) tableView:(UITableView *)tableView cellIdentifierForRowAtIndexPath:(NSIndexPath *)indexPath {
	id row;
	if (tableView == self.tableView)
		row = self.rows[indexPath.row];
	else
		row = self.searchResults[indexPath.section][@"rows"][indexPath.row];
	
	if ([row isKindOfClass:[NCDBMapRegion class]])
		return @"RegionCell";
	else
		return @"SolarSystemCell";
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
		NCDefaultTableViewCell* cell = (NCDefaultTableViewCell*) tableViewCell;
		cell.object = row;
		cell.titleLabel.text = [row solarSystemName];
	}
}

@end
