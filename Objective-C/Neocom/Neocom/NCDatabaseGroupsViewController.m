//
//  NCDatabaseGroupsViewController.m
//  Neocom
//
//  Created by Artem Shimanski on 20.11.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCDatabaseGroupsViewController.h"
#import "NCDatabase.h"
#import "NCTableViewDefaultCell.h"
#import "NCDatabaseTypesViewController.h"

@interface NCDatabaseGroupsViewController ()<UISearchResultsUpdating>
@property (nonatomic, strong) NSFetchedResultsController* results;
@property (nonatomic, strong) UISearchController *searchController;
@end

@implementation NCDatabaseGroupsViewController

- (void) viewDidLoad {
	[super viewDidLoad];
	[self setupSearchController];

	NSFetchRequest* request = [NCDBInvGroup fetchRequest];
	request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"published" ascending:NO], [NSSortDescriptor sortDescriptorWithKey:@"groupName" ascending:YES]];
	request.predicate = [NSPredicate predicateWithFormat:@"category == %@ AND types.@count > 0", self.category];
	self.results = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:NCDatabase.sharedDatabase.viewContext sectionNameKeyPath:@"published" cacheName:nil];
	[self.results performFetch:nil];
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	if ([segue.identifier isEqualToString:@"NCDatabaseTypesViewController"]) {
		NCDatabaseTypesViewController* controller = segue.destinationViewController;
		controller.predicate = [NSPredicate predicateWithFormat:@"group == %@", [sender object]];
		controller.title = [[sender object] groupName];
	}
}

#pragma mark - UITableViewDataSource

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
	return self.results.sections.count;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return [self.results.sections[section] numberOfObjects];
}

- (UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	NCTableViewDefaultCell* cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
	NCDBInvGroup* group = [self.results objectAtIndexPath:indexPath];
	cell.titleLabel.text = group.groupName;
	cell.iconView.image = (id) group.icon.image.image ?: NCDBEveIcon.defaultGroupIcon.image.image;
	cell.object = group;
	return cell;
}

- (NSString*) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	NSString* name = [self.results.sections[section] name];
	if ([name integerValue] == 0)
		return NSLocalizedString(@"Unpublished", nil);
	else
		return nil;
}

#pragma mark - UISearchResultsUpdating

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {
	NSPredicate* predicate;
	if (searchController.searchBar.text.length > 2) {
		predicate = [NSPredicate predicateWithFormat:@"group.category == %@ AND typeName CONTAINS[C] %@", self.category, searchController.searchBar.text];
	}
	else
		predicate = [NSPredicate predicateWithValue:NO];
	NCDatabaseTypesViewController* controller = (NCDatabaseTypesViewController*) self.searchController.searchResultsController;
	controller.predicate = predicate;
	[controller reloadData];
}

#pragma mark - Private

- (void) setupSearchController {
	self.searchController = [[UISearchController alloc] initWithSearchResultsController:[self.storyboard instantiateViewControllerWithIdentifier:@"NCDatabaseTypesViewController"]];
	self.searchController.searchBar.searchBarStyle = UISearchBarStyleDefault;
	self.searchController.searchResultsUpdater = self;
	self.searchController.searchBar.barStyle = UIBarStyleBlack;
	self.tableView.backgroundView = [UIView new];
	self.tableView.tableHeaderView = self.searchController.searchBar;
	self.definesPresentationContext = YES;
}


@end
