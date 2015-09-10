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
@property (nonatomic, strong) NSFetchedResultsController* result;
@property (nonatomic, strong) NSFetchedResultsController* searchResult;
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

	if (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_7_1) {
        if (self.parentViewController) {
            self.searchController = [[UISearchController alloc] initWithSearchResultsController:[self.storyboard instantiateViewControllerWithIdentifier:@"NCDatabaseSolarSystemPickerViewController"]];
        }
        else {
            self.tableView.tableHeaderView = nil;
            return;
        }
    }

	if (self.region) {
		self.title = self.region.regionName;
		self.databaseManagedObjectContext = self.region.managedObjectContext;
	}
	
	self.refreshControl = nil;
	
	if (!self.result) {
		if (self.region) {
			NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"MapSolarSystem"];
			request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"solarSystemName" ascending:YES]];
			request.predicate = [NSPredicate predicateWithFormat:@"constellation.region == %@", self.region];
			request.fetchBatchSize = 50;
			self.result = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:self.databaseManagedObjectContext sectionNameKeyPath:nil cacheName:nil];
			[self.result performFetch:nil];
		}
		else {
			NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"MapRegion"];
			request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"regionName" ascending:YES]];
			request.fetchBatchSize = 50;
			self.result = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:self.databaseManagedObjectContext sectionNameKeyPath:nil cacheName:nil];
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
	if (tableView == self.tableView && !self.searchContentsController)
		return 1;
	else
		return self.searchResult.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	id <NSFetchedResultsSectionInfo> sectionInfo = tableView == self.tableView ? self.result.sections[section] : self.searchResult.sections[section];
	return sectionInfo.numberOfObjects;
}

- (NSString*) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	id <NSFetchedResultsSectionInfo> sectionInfo = tableView == self.tableView ? self.result.sections[section] : self.searchResult.sections[section];
	return sectionInfo.name.length > 0 ? sectionInfo.name : nil;
}

#pragma mark - NCTableViewController

- (void) searchWithSearchString:(NSString*) searchString {
	if (self.region) {
		NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"MapSolarSystem"];
		request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"constellation.region.regionName" ascending:YES], [NSSortDescriptor sortDescriptorWithKey:@"solarSystemName" ascending:YES]];
		request.predicate = [NSPredicate predicateWithFormat:@"constellation.region == %@ AND solarSystemName CONTAINS[C] %@", self.region, searchString];
		request.fetchBatchSize = 50;
		self.searchResult = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:self.databaseManagedObjectContext sectionNameKeyPath:@"constellation.region.regionName" cacheName:nil];
	}
	else {
		NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"MapSolarSystem"];
		request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"constellation.region.regionName" ascending:YES], [NSSortDescriptor sortDescriptorWithKey:@"solarSystemName" ascending:YES]];
		request.predicate = [NSPredicate predicateWithFormat:@"solarSystemName CONTAINS[C] %@", searchString];
		request.fetchBatchSize = 50;
		self.searchResult = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:self.databaseManagedObjectContext sectionNameKeyPath:@"constellation.region.regionName" cacheName:nil];
	}
	[self.searchResult performFetch:nil];
	
    if (self.searchController) {
        NCDatabaseSolarSystemPickerViewController* searchResultsController = (NCDatabaseSolarSystemPickerViewController*) self.searchController.searchResultsController;
        searchResultsController.searchResult = self.searchResult;
        [searchResultsController.tableView reloadData];
    }
    else if (self.searchDisplayController)
        [self.searchDisplayController.searchResultsTableView reloadData];
}

- (NSString*) tableView:(UITableView *)tableView cellIdentifierForRowAtIndexPath:(NSIndexPath *)indexPath {
	id row = tableView == self.tableView && !self.searchContentsController ? [self.result objectAtIndexPath:indexPath] : [self.searchResult objectAtIndexPath:indexPath];
	
	if ([row isKindOfClass:[NCDBMapRegion class]])
		return @"RegionCell";
	else
		return @"SolarSystemCell";
}

- (void) tableView:(UITableView *)tableView configureCell:(UITableViewCell*) tableViewCell forRowAtIndexPath:(NSIndexPath*) indexPath {
	id row = tableView == self.tableView && !self.searchContentsController ? [self.result objectAtIndexPath:indexPath] : [self.searchResult objectAtIndexPath:indexPath];
	
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
