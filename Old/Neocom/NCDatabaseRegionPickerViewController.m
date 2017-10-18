//
//  NCDatabaseRegionPickerViewController.m
//  Neocom
//
//  Created by Артем Шиманский on 24.12.15.
//  Copyright © 2015 Artem Shimanski. All rights reserved.
//

#import "NCDatabaseRegionPickerViewController.h"
#import "NCTableViewCell.h"
#import "NCDatabaseSolarSystemPickerRegionCell.h"

@interface NCDatabaseRegionPickerViewController ()
@property (nonatomic, strong) NSFetchedResultsController* result;
@property (nonatomic, strong) NSFetchedResultsController* searchResult;
@property (nonatomic, strong) NSArray* regionIDs;
@end

@implementation NCDatabaseRegionPickerViewController

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
	
	//self.refreshControl = nil;
	
	if (!self.result) {
		NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"StaStation"];
		NSExpressionDescription* e = [NSExpressionDescription new];
		e.expression = [NSExpression expressionForKeyPath:@"solarSystem.constellation.region.regionID"];
		e.expressionResultType = NSInteger32AttributeType;
		e.name = @"regionID";
		request.propertiesToFetch = @[e];
		request.resultType = NSDictionaryResultType;
		request.propertiesToGroupBy = request.propertiesToFetch;
		self.regionIDs = [[self.databaseManagedObjectContext executeFetchRequest:request error:nil] valueForKey:@"regionID"];
	}
	self.cacheRecordID = @"EVEConquerableStationList";
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
	[super prepareForSegue:segue sender:sender];
	if ([segue.identifier isEqualToString:@"Unwind"]) {
		self.selectedRegion = [sender object];
	}
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	id <NSFetchedResultsSectionInfo> sectionInfo = self.result.sections[section];
	return sectionInfo.numberOfObjects;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	if (self.searchContentsController) {
//		[self.searchContentsController.searchController setActive:NO];
		[self.parentViewController dismissViewControllerAnimated:NO completion:^{
			[self.searchContentsController performSegueWithIdentifier:@"Unwind" sender:[tableView cellForRowAtIndexPath:indexPath]];
		}];
	}
	else
		[self performSegueWithIdentifier:@"Unwind" sender:[tableView cellForRowAtIndexPath:indexPath]];
}


#pragma mark - NCTableViewController

- (void) downloadDataWithCachePolicy:(NSURLRequestCachePolicy)cachePolicy completionBlock:(void (^)(NSError *))completionBlock {
	NSProgress* progress = [NSProgress progressWithTotalUnitCount:1];
	EVEOnlineAPI* api = [[EVEOnlineAPI alloc] initWithAPIKey:nil cachePolicy:NSURLRequestUseProtocolCachePolicy];
	[api conquerableStationListWithCompletionBlock:^(EVEConquerableStationList *result, NSError *error) {
		progress.completedUnitCount++;
		NSMutableDictionary* conquerableStations = [NSMutableDictionary new];
		for (EVEConquerableStationListItem* item in result.outposts)
			conquerableStations[@(item.stationID)] = item;

		[self saveCacheData:conquerableStations cacheDate:[NSDate date] expireDate:[NSDate dateWithTimeIntervalSinceNow:60*60*24*7]];
		completionBlock(nil);
	}];
}

- (void) loadCacheData:(id)cacheData withCompletionBlock:(void (^)())completionBlock {
	NSDictionary* result = self.cacheData;
	
	NSSet* set = [NSSet setWithArray:[[result allValues] valueForKey:@"solarSystemID"]];
	NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"MapSolarSystem"];
	request.predicate = [NSPredicate predicateWithFormat:@"solarSystemID IN %@", set];
	NSExpressionDescription* e = [NSExpressionDescription new];
	e.expression = [NSExpression expressionForKeyPath:@"constellation.region.regionID"];
	e.expressionResultType = NSInteger32AttributeType;
	e.name = @"regionID";
	request.propertiesToFetch = @[e];
	request.resultType = NSDictionaryResultType;
	request.propertiesToGroupBy = request.propertiesToFetch;
	NSArray* regionIDs = [[self.databaseManagedObjectContext executeFetchRequest:request error:nil] valueForKey:@"regionID"];
	NSMutableSet* mset = [[NSMutableSet alloc] initWithArray:self.regionIDs];
	[mset unionSet:[NSSet setWithArray:regionIDs]];
	self.regionIDs = [mset allObjects];
	
	request = [NSFetchRequest fetchRequestWithEntityName:@"MapRegion"];
	request.predicate = [NSPredicate predicateWithFormat:@"regionID IN %@", self.regionIDs];
	request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"regionName" ascending:YES]];
	request.fetchBatchSize = 50;
	self.result = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:self.databaseManagedObjectContext sectionNameKeyPath:nil cacheName:nil];
	[self.result performFetch:nil];

	completionBlock();
}

- (void) searchWithSearchString:(NSString*) searchString completionBlock:(void (^)())completionBlock {
	NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"MapRegion"];
	request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"regionName" ascending:YES]];
	request.predicate = [NSPredicate predicateWithFormat:@"regionName CONTAINS[C] %@ AND regionID IN %@", searchString, self.regionIDs];
	request.fetchBatchSize = 50;
	self.searchResult = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:self.databaseManagedObjectContext sectionNameKeyPath:nil cacheName:nil];
	[self.searchResult performFetch:nil];
	
	[(NCDatabaseRegionPickerViewController*) self.searchController.searchResultsController setResult:self.searchResult];
	completionBlock();
}

- (NSString*) tableView:(UITableView *)tableView cellIdentifierForRowAtIndexPath:(NSIndexPath *)indexPath {
	return @"Cell";
}

- (void) tableView:(UITableView *)tableView configureCell:(UITableViewCell*) tableViewCell forRowAtIndexPath:(NSIndexPath*) indexPath {
	id row = [self.result objectAtIndexPath:indexPath];
	
	NCDatabaseSolarSystemPickerRegionCell* cell = (NCDatabaseSolarSystemPickerRegionCell*) tableViewCell;
	cell.object = row;
	cell.titleLabel.text = [row regionName];
}

@end
