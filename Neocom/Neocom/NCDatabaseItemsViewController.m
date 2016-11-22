//
//  NCDatabaseItemsViewController.m
//  Neocom
//
//  Created by Artem Shimanski on 20.11.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCDatabaseItemsViewController.h"
#import "NCDatabase.h"
#import "NCTableViewDefaultCell.h"
#import "NCTableViewBackgroundLabel.h"
#import "NCGate.h"
#import "NSExpressionDescription+NC.h"

@interface NCDatabaseItemsViewController ()<UISearchResultsUpdating>
@property (strong, nonatomic) NSFetchedResultsController* results;
@property (nonatomic, strong) UISearchController *searchController;
@property (strong, nonatomic) NCGate* gate;

@end

@implementation NCDatabaseItemsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
	if (self.navigationController)
		[self setupSearchController];
	self.gate = [NCGate new];
	[self reloadData];
}

- (void) reloadData {
	[self.gate performBlock:^{
		[NCDatabase.sharedDatabase performTaskAndWait:^(NSManagedObjectContext *managedObjectContext) {
			NSFetchRequest* request = [NCDBInvType fetchRequest];
			request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"metaGroup.metaGroupID" ascending:YES],
										[NSSortDescriptor sortDescriptorWithKey:@"metaLevel" ascending:YES],
										[NSSortDescriptor sortDescriptorWithKey:@"typeName" ascending:YES]];
			request.predicate = self.predicate ?: [NSPredicate predicateWithValue:NO];
			NSMutableArray* properties = [NSMutableArray new];
			NSEntityDescription* entity = managedObjectContext.persistentStoreCoordinator.managedObjectModel.entitiesByName[request.entityName];
			NSDictionary* propertiesByName = entity.propertiesByName;
			[properties addObject:propertiesByName[@"typeID"]];
			[properties addObject:propertiesByName[@"typeName"]];
			[properties addObject:propertiesByName[@"metaLevel"]];
			[properties addObject:[NSExpressionDescription expressionDescriptionWithName:@"metaGroupID" resultType:NSInteger32AttributeType expression:[NSExpression expressionForKeyPath:@"metaGroup.metaGroupID"]]];
			[properties addObject:[NSExpressionDescription expressionDescriptionWithName:@"icon" resultType:NSObjectIDAttributeType expression:[NSExpression expressionForKeyPath:@"icon"]]];
			[properties addObject:[NSExpressionDescription expressionDescriptionWithName:@"metaGroupName" resultType:NSStringAttributeType expression:[NSExpression expressionForKeyPath:@"metaGroup.metaGroupName"]]];
			request.propertiesToFetch = properties;
			
			request.resultType = NSDictionaryResultType;
			NSFetchedResultsController* results = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:NCDatabase.sharedDatabase.viewContext sectionNameKeyPath:@"metaGroupName" cacheName:nil];
			
			[results performFetch:nil];
			
			dispatch_async(dispatch_get_main_queue(), ^{
				self.results = results;
				[self.tableView reloadData];
				self.tableView.backgroundView = self.results.fetchedObjects.count == 0 ? [NCTableViewBackgroundLabel labelWithText:NSLocalizedString(@"No Results", nil)] : nil;

			});
		}];
	}];
/*	NSFetchRequest* request = [NCDBInvType fetchRequest];
	request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"metaGroup.metaGroupID" ascending:YES],
								[NSSortDescriptor sortDescriptorWithKey:@"metaLevel" ascending:YES],
								[NSSortDescriptor sortDescriptorWithKey:@"typeName" ascending:YES]];
	request.predicate = self.predicate ?: [NSPredicate predicateWithValue:NO];
	//request.resultType = NSDictionaryResultType;
	self.results = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:NCDatabase.sharedDatabase.viewContext sectionNameKeyPath:@"metaGroupName" cacheName:nil];
	[self.results performFetch:nil];
	[self.tableView reloadData];
	self.tableView.backgroundView = self.results.fetchedObjects.count == 0 ? [NCTableViewBackgroundLabel labelWithText:NSLocalizedString(@"No Results", nil)] : nil;*/
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
	//NCDBInvType* type = [self.results objectAtIndexPath:indexPath];
	NSDictionary* type = [self.results objectAtIndexPath:indexPath];
	cell.titleLabel.text = type[@"typeName"];
	NCDBEveIcon* icon = type[@"icon"] ? [NCDatabase.sharedDatabase.viewContext existingObjectWithID:type[@"icon"] error:nil] : nil;
	cell.iconView.image = (id) icon.image.image ?: NCDBEveIcon.defaultTypeIcon.image.image;
//	cell.titleLabel.text = type.typeName;
//	cell.iconView.image = (id) type.icon.image.image ?: NCDBEveIcon.defaultTypeIcon.image.image;
	cell.object = type;
	return cell;
}

- (NSString*) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	return [self.results.sections[section] name];
}

#pragma mark - UISearchResultsUpdating

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {
	NSPredicate* predicate;
	if (searchController.searchBar.text.length > 0 && self.predicate) {
		predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[self.predicate, [NSPredicate predicateWithFormat:@"typeName CONTAINS[C] %@", searchController.searchBar.text]]];
	}
	else
		predicate = [NSPredicate predicateWithValue:NO];
	NCDatabaseItemsViewController* controller = (NCDatabaseItemsViewController*) self.searchController.searchResultsController;
	controller.predicate = predicate;
	[controller reloadData];
}

#pragma mark - Private

- (void) setupSearchController {
	self.searchController = [[UISearchController alloc] initWithSearchResultsController:[self.storyboard instantiateViewControllerWithIdentifier:@"NCDatabaseItemsViewController"]];
	self.searchController.searchBar.searchBarStyle = UISearchBarStyleDefault;
	self.searchController.searchResultsUpdater = self;
	self.searchController.searchBar.barStyle = UIBarStyleBlack;
	self.tableView.backgroundView = [UIView new];
	self.tableView.tableHeaderView = self.searchController.searchBar;
	self.definesPresentationContext = YES;
}


@end
