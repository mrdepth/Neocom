//
//  NCDatabaseWHViewController.m
//  Neocom
//
//  Created by Артем Шиманский on 16.04.15.
//  Copyright (c) 2015 Artem Shimanski. All rights reserved.
//

#import "NCDatabaseWHViewController.h"
#import "NCDatabaseTypeInfoViewController.h"
#import "NSNumberFormatter+Neocom.h"

@interface NCDatabaseWHViewController()
@property (nonatomic, strong) NSFetchedResultsController* result;
@property (nonatomic, strong) NSFetchedResultsController* searchResult;
@property (nonatomic, strong) NCDBEveIcon* defaultTypeIcon;
- (void) reload;
@end

@implementation NCDatabaseWHViewController

- (void)viewDidLoad {
	[super viewDidLoad];
	self.refreshControl = nil;
	self.defaultTypeIcon = [self.databaseManagedObjectContext defaultTypeIcon];

    if (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_7_1) {
        if (self.parentViewController) {
            self.searchController = [[UISearchController alloc] initWithSearchResultsController:[self.storyboard instantiateViewControllerWithIdentifier:@"NCDatabaseWHViewController"]];
			[(NCDatabaseWHViewController*) self.searchController.searchResultsController setDatabaseManagedObjectContext:self.databaseManagedObjectContext];
        }
        else {
            self.tableView.tableHeaderView = nil;
            return;
        }
    }
    
	if (!self.result)
		[self reload];
}

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	if ([segue.identifier isEqualToString:@"NCDatabaseTypeInfoViewController"]) {
		NCDatabaseTypeInfoViewController* controller;
		if ([segue.destinationViewController isKindOfClass:[UINavigationController class]])
			controller = [segue.destinationViewController viewControllers][0];
		else
			controller = segue.destinationViewController;
		
		id row = [sender object];
		controller.typeID = [row objectID];
	}
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return tableView == self.tableView && !self.searchContentsController ? self.result.sections.count : self.searchResult.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	id<NSFetchedResultsSectionInfo> sectionInfo = tableView == self.tableView && !self.searchContentsController ? self.result.sections[section] : self.searchResult.sections[section];
	return sectionInfo.numberOfObjects;
}

- (NSString*) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	id<NSFetchedResultsSectionInfo> sectionInfo = tableView == self.tableView && !self.searchContentsController ? self.result.sections[section] : self.searchResult.sections[section];
	return sectionInfo.name;
}

#pragma mark - NCTableViewController

- (void) searchWithSearchString:(NSString*) searchString {
	if (searchString.length >= 1) {
		NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"WhType"];
		request.predicate = [NSPredicate predicateWithFormat:@"type.typeName CONTAINS[C] %@", searchString];
		request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"targetSystemClass" ascending:YES],
									[NSSortDescriptor sortDescriptorWithKey:@"type.typeName" ascending:YES]];
		NSFetchedResultsController* controller = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:self.databaseManagedObjectContext sectionNameKeyPath:@"targetSystemClassDisplayName" cacheName:nil];
		
		[controller performFetch:nil];
		self.searchResult = controller;
	}
	else {
		self.searchResult = nil;
	}
    
    if (self.searchController) {
        NCDatabaseWHViewController* searchResultsController = (NCDatabaseWHViewController*) self.searchController.searchResultsController;
        searchResultsController.searchResult = self.searchResult;
        [searchResultsController.tableView reloadData];
    }
    else if (self.searchDisplayController)
        [self.searchDisplayController.searchResultsTableView reloadData];

}

- (void) tableView:(UITableView *)tableView configureCell:(NCDefaultTableViewCell*) cell forRowAtIndexPath:(NSIndexPath*) indexPath {
	NCDBWhType* row = tableView == self.tableView && !self.searchContentsController ? [self.result objectAtIndexPath:indexPath] : [self.searchResult objectAtIndexPath:indexPath];
	
	cell.titleLabel.text = row.type.typeName;
	if (row.maxJumpMass > 0)
		cell.subtitleLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%@ / %@ kg", nil), [NSNumberFormatter neocomLocalizedStringFromNumber:@(row.maxJumpMass)], [NSNumberFormatter neocomLocalizedStringFromNumber:@(row.maxStableMass)]];
	else
		cell.subtitleLabel.text = nil;
	cell.iconView.image = row.type.icon ? row.type.icon.image.image : self.defaultTypeIcon.image.image;
	cell.object = row.type;
}

- (NSString*) tableView:(UITableView *)tableView cellIdentifierForRowAtIndexPath:(NSIndexPath *)indexPath {
	return @"Cell";
}

#pragma mark - Private

- (void) reload {
	NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"WhType"];
	request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"targetSystemClass" ascending:YES],
								[NSSortDescriptor sortDescriptorWithKey:@"type.typeName" ascending:YES]];
	NSFetchedResultsController* controller = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:self.databaseManagedObjectContext sectionNameKeyPath:@"targetSystemClassDisplayName" cacheName:nil];
	
	[controller performFetch:nil];
	self.result = controller;
	[self.tableView reloadData];
}


@end
