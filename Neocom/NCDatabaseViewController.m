//
//  NCDatabaseViewController.m
//  Neocom
//
//  Created by Артем Шиманский on 14.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCDatabaseViewController.h"
#import "NCDatabaseTypeInfoViewController.h"
#import "NCTableViewCell.h"

@interface NCDatabaseViewController ()
@property (nonatomic, strong) NSFetchedResultsController* result;
@property (nonatomic, strong) NSFetchedResultsController* searchResult;
@property (nonatomic, strong) NCDBEveIcon* defaultGroupIcon;
@property (nonatomic, strong) NCDBEveIcon* defaultTypeIcon;

- (void) reload;
@end

@implementation NCDatabaseViewController

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
	if (self.group) {
		self.title = self.group.groupName;
	}
	else if (self.category) {
		self.title = self.category.categoryName;
	}
	
	self.defaultGroupIcon = [self.databaseManagedObjectContext defaultGroupIcon];
	self.defaultTypeIcon = [self.databaseManagedObjectContext defaultTypeIcon];

	self.refreshControl = nil;
	
	if (self.filter == NCDatabaseFilterAll)
		self.navigationItem.rightBarButtonItem.title = NSLocalizedString(@"All", nil);
	else if (self.filter == NCDatabaseFilterPublished)
		self.navigationItem.rightBarButtonItem.title = NSLocalizedString(@"Published", nil);
	else if (self.filter == NCDatabaseFilterUnpublished)
		self.navigationItem.rightBarButtonItem.title = NSLocalizedString(@"Unpublished", nil);
	
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void) viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	if (!self.result) {
		[self reload];
	}
}

- (void) viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	if ([segue.identifier isEqualToString:@"NCDatabaseViewController"]) {
		id row = [sender object];
		
		NCDatabaseViewController* destinationViewController = segue.destinationViewController;
		if ([row isKindOfClass:[NCDBInvCategory class]])
			destinationViewController.category = row;
		else if ([row isKindOfClass:[NCDBInvGroup class]])
			destinationViewController.group = row;
		destinationViewController.filter = self.filter;
	}
	else {
		NCDatabaseTypeInfoViewController* controller;
		if ([segue.destinationViewController isKindOfClass:[UINavigationController class]])
			controller = [segue.destinationViewController viewControllers][0];
		else
			controller = segue.destinationViewController;
		
		id row = [sender object];
		controller.typeID = [row objectID];
	}
}

- (NSManagedObjectContext*) databaseManagedObjectContext {
	return self.group.managedObjectContext ?: self.category.managedObjectContext ?: [super databaseManagedObjectContext];
}

- (IBAction)onFilter:(id)sender {
	UIAlertController* controller = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
	[controller addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"All", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
		self.filter = NCDatabaseFilterAll;
		self.navigationItem.rightBarButtonItem.title = action.title;
		[self reload];
	}]];
	[controller addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Published", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
		self.filter = NCDatabaseFilterPublished;
		self.navigationItem.rightBarButtonItem.title = action.title;
		[self reload];
	}]];
	[controller addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Unpublished", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
		self.filter = NCDatabaseFilterUnpublished;
		self.navigationItem.rightBarButtonItem.title = action.title;
		[self reload];
	}]];
	[controller addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
	}]];
	
	[controller presentViewController:controller animated:YES completion:nil];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return tableView == self.tableView ? self.result.sections.count : self.searchResult.sections.count;
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

- (void) searchWithSearchString:(NSString*) searchString completionBlock:(void (^)())completionBlock {
	if (searchString.length >= 2) {
		if (self.group) {
			NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"InvType"];
			request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"typeName" ascending:YES]];
			
			if (self.filter == NCDatabaseFilterPublished)
				request.predicate = [NSPredicate predicateWithFormat:@"group == %@ AND published == TRUE AND typeName LIKE[C] %@", self.group, searchString];
			else if (self.filter == NCDatabaseFilterUnpublished)
				request.predicate = [NSPredicate predicateWithFormat:@"group == %@ AND published == FALSE AND typeName LIKE[C] %@", self.group, searchString];
			else
				request.predicate = [NSPredicate predicateWithFormat:@"group == %@ AND typeName LIKE[C] %@", self.group, searchString];
			
			request.fetchBatchSize = 50;
			self.searchResult = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:self.databaseManagedObjectContext sectionNameKeyPath:nil cacheName:nil];
		}
		else if (self.category) {
			NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"InvType"];
			request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"typeName" ascending:YES]];
			
			if (self.filter == NCDatabaseFilterPublished)
				request.predicate = [NSPredicate predicateWithFormat:@"group.category == %@ AND published == TRUE AND typeName LIKE[C] %@", self.category, searchString];
			else if (self.filter == NCDatabaseFilterUnpublished)
				request.predicate = [NSPredicate predicateWithFormat:@"group.category == %@ AND published == FALSE AND typeName LIKE[C] %@", self.category, searchString];
			else
				request.predicate = [NSPredicate predicateWithFormat:@"group.category == %@ AND typeName LIKE[C] %@", self.category, searchString];
			
			request.fetchBatchSize = 50;
			self.searchResult = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:self.databaseManagedObjectContext sectionNameKeyPath:nil cacheName:nil];
		}
		else {
			NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"InvType"];
			request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"typeName" ascending:YES]];

			if (self.filter == NCDatabaseFilterPublished)
				request.predicate = [NSPredicate predicateWithFormat:@"published == TRUE AND typeName CONTAINS[C] %@", searchString];
			else if (self.filter == NCDatabaseFilterUnpublished)
				request.predicate = [NSPredicate predicateWithFormat:@"published == FALSE AND typeName CONTAINS[C] %@", searchString];
			else
				request.predicate = [NSPredicate predicateWithFormat:@"typeName CONTAINS[C] %@", searchString];
			
			request.fetchBatchSize = 50;
			self.searchResult = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:self.databaseManagedObjectContext sectionNameKeyPath:nil cacheName:nil];
		}
		NSError* error = nil;
		[self.searchResult performFetch:&error];
	}
	else {
		self.searchResult = nil;
	}
	
	[(NCDatabaseViewController*) self.searchController.searchResultsController setResult:self.searchResult];
	completionBlock();
}

- (void) tableView:(UITableView *)tableView configureCell:(NCDefaultTableViewCell*) cell forRowAtIndexPath:(NSIndexPath*) indexPath {
	id row = tableView == self.tableView ? [self.result objectAtIndexPath:indexPath] : [self.searchResult objectAtIndexPath:indexPath];
	
	if ([row isKindOfClass:[NCDBInvType class]]) {
		NCDBInvType* type = row;
		cell.titleLabel.text = type.typeName;
		cell.iconView.image = type.icon ? type.icon.image.image : self.defaultTypeIcon.image.image;
		cell.object = row;
	}
	else {
		if ([row isKindOfClass:[NCDBInvCategory class]]) {
			NCDBInvCategory* category = row;
			cell.titleLabel.text = category.categoryName;
			cell.iconView.image = category.icon.image.image;
		}
		else {
			NCDBInvGroup* group = row;
			cell.titleLabel.text = group.groupName;
			cell.iconView.image = group.icon.image.image;
		}
		
		if (!cell.iconView.image)
			cell.iconView.image = self.defaultGroupIcon.image.image;
		cell.object = row;
	}
}

- (NSString*) tableView:(UITableView *)tableView cellIdentifierForRowAtIndexPath:(NSIndexPath *)indexPath {
	id row = tableView == self.tableView ? [self.result objectAtIndexPath:indexPath] : [self.searchResult objectAtIndexPath:indexPath];
	if ([row isKindOfClass:[NCDBInvType class]])
		return @"TypeCell";
	else
		return @"CategoryGroupCell";
}

#pragma mark - Private

- (void) reload {
	if (self.group) {
		NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"InvType"];
		request.sortDescriptors = @[
									[NSSortDescriptor sortDescriptorWithKey:@"metaGroup.metaGroupID" ascending:YES],
									[NSSortDescriptor sortDescriptorWithKey:@"metaLevel" ascending:YES],
									[NSSortDescriptor sortDescriptorWithKey:@"typeName" ascending:YES]];
		
		if (self.filter == NCDatabaseFilterPublished)
			request.predicate = [NSPredicate predicateWithFormat:@"group == %@ AND published == TRUE", self.group];
		else if (self.filter == NCDatabaseFilterUnpublished)
			request.predicate = [NSPredicate predicateWithFormat:@"group == %@ AND published == FALSE", self.group];
		else
			request.predicate = [NSPredicate predicateWithFormat:@"group == %@", self.group];

		self.result = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:self.databaseManagedObjectContext sectionNameKeyPath:@"metaGroupName" cacheName:nil];
	}
	else if (self.category) {
		NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"InvGroup"];
		request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"groupName" ascending:YES]];
		
		if (self.filter == NCDatabaseFilterPublished)
			request.predicate = [NSPredicate predicateWithFormat:@"category == %@ AND published == TRUE", self.category];
		else if (self.filter == NCDatabaseFilterUnpublished)
			request.predicate = [NSPredicate predicateWithFormat:@"category == %@ AND published == FALSE", self.category];
		else
			request.predicate = [NSPredicate predicateWithFormat:@"category == %@", self.category];

		self.result = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:self.databaseManagedObjectContext sectionNameKeyPath:nil cacheName:nil];
	}
	else {
		NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"InvCategory"];
		request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"categoryName" ascending:YES]];

		if (self.filter == NCDatabaseFilterPublished)
			request.predicate = [NSPredicate predicateWithFormat:@"published == TRUE"];
		else if (self.filter == NCDatabaseFilterUnpublished)
			request.predicate = [NSPredicate predicateWithFormat:@"published == FALSE"];

		self.result = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:self.databaseManagedObjectContext sectionNameKeyPath:nil cacheName:nil];
	}
	NSError* error = nil;
	[self.result performFetch:&error];
	[self.tableView reloadData];
}

@end
