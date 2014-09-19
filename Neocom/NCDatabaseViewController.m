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
#import "UIActionSheet+Block.h"

@interface NCDatabaseViewController ()
@property (nonatomic, strong) NSFetchedResultsController* result;
@property (nonatomic, strong) NSFetchedResultsController* searchResult;
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
	if (self.group)
		self.title = self.group.groupName;
	else if (self.category)
		self.title = self.category.categoryName;
	self.refreshControl = nil;
	
	if (!self.result) {
		[self reload];
	}
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
		controller.type = row;
	}
}

- (IBAction)onFilter:(id)sender {
	[[UIActionSheet actionSheetWithStyle:UIActionSheetStyleBlackTranslucent
								   title:nil
					   cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
				  destructiveButtonTitle:nil
					   otherButtonTitles:@[NSLocalizedString(@"All", nil), NSLocalizedString(@"Published", nil), NSLocalizedString(@"Unpublished", nil)]
						 completionBlock:^(UIActionSheet *actionSheet, NSInteger selectedButtonIndex) {
							 if (selectedButtonIndex != actionSheet.cancelButtonIndex) {
								 if (selectedButtonIndex == 0)
									 self.filter = NCDatabaseFilterAll;
								 else if (selectedButtonIndex == 1)
									 self.filter = NCDatabaseFilterPublished;
								 else if (selectedButtonIndex == 2)
									 self.filter = NCDatabaseFilterUnpublished;
								 self.navigationItem.rightBarButtonItem.title = [actionSheet buttonTitleAtIndex:selectedButtonIndex];
								 [self reload];
							 }
						 }
							 cancelBlock:nil] showFromBarButtonItem:sender animated:YES];
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

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	id row = tableView == self.tableView ? [self.result objectAtIndexPath:indexPath] : [self.searchResult objectAtIndexPath:indexPath];
	if ([row isKindOfClass:[NCDBInvType class]]) {
		static NSString *CellIdentifier = @"TypeCell";
		NCTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
		if (!cell)
			cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier];
		[self tableView:tableView configureCell:cell forRowAtIndexPath:indexPath];
		return cell;
	}
	else {
		static NSString *CellIdentifier = @"CategoryGroupCell";
		NCTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
		if (!cell)
			cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier];
		
		[self tableView:tableView configureCell:cell forRowAtIndexPath:indexPath];
		return cell;
	}
}

- (NSString*) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	id <NSFetchedResultsSectionInfo> sectionInfo = tableView == self.tableView ? self.result.sections[section] : self.searchResult.sections[section];
	return sectionInfo.name.length > 0 ? sectionInfo.name : nil;
}

#pragma mark - Table view delegate

- (CGFloat) tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return 37;
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_6_1)
		return [self tableView:tableView estimatedHeightForRowAtIndexPath:indexPath];
	
	id row = tableView == self.tableView ? [self.result objectAtIndexPath:indexPath] : [self.searchResult objectAtIndexPath:indexPath];

	NSString *CellIdentifier;
	if ([row isKindOfClass:[NCDBInvType class]])
		CellIdentifier = @"TypeCell";
	else
		CellIdentifier = @"CategoryGroupCell";
	
	UITableViewCell* cell = [self tableView:self.tableView offscreenCellWithIdentifier:CellIdentifier];
	[self tableView:tableView configureCell:cell forRowAtIndexPath:indexPath];
	
	cell.bounds = CGRectMake(0, 0, CGRectGetWidth(tableView.bounds), CGRectGetHeight(cell.bounds));
	[cell layoutIfNeeded];
	if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_7_1)
		return [cell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height + 1.0;
	else
		return [cell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize withHorizontalFittingPriority:1000 verticalFittingPriority:1].height + 1.0;
}

#pragma mark - NCTableViewController

- (NSString*) recordID {
	return nil;
}

- (void) searchWithSearchString:(NSString*) searchString {
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
			
			NCDatabase* database = [NCDatabase sharedDatabase];
			request.fetchBatchSize = 50;
			self.searchResult = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:database.managedObjectContext sectionNameKeyPath:nil cacheName:nil];
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
			
			NCDatabase* database = [NCDatabase sharedDatabase];
			request.fetchBatchSize = 50;
			self.searchResult = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:database.managedObjectContext sectionNameKeyPath:nil cacheName:nil];
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
			
			NCDatabase* database = [NCDatabase sharedDatabase];
			request.fetchBatchSize = 50;
			self.searchResult = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:database.managedObjectContext sectionNameKeyPath:nil cacheName:nil];
		}
		NSError* error = nil;
		[self.searchResult performFetch:&error];
		[self.searchDisplayController.searchResultsTableView reloadData];
	}
	else {
		self.searchResult = nil;
		[self.searchDisplayController.searchResultsTableView reloadData];
	}
}

- (void) tableView:(UITableView *)tableView configureCell:(NCTableViewCell*) cell forRowAtIndexPath:(NSIndexPath*) indexPath {
	id row = tableView == self.tableView ? [self.result objectAtIndexPath:indexPath] : [self.searchResult objectAtIndexPath:indexPath];
	
	if ([row isKindOfClass:[NCDBInvType class]]) {
		NCDBInvType* type = row;
		cell.titleLabel.text = type.typeName;
		cell.iconView.image = type.icon ? type.icon.image.image : [[[NCDBEveIcon defaultTypeIcon] image] image];
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
			cell.iconView.image = [[[NCDBEveIcon defaultGroupIcon] image] image];
		cell.object = row;
	}
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

		NCDatabase* database = [NCDatabase sharedDatabase];
		self.result = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:database.managedObjectContext sectionNameKeyPath:@"metaGroupName" cacheName:nil];
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

		NCDatabase* database = [NCDatabase sharedDatabase];
		self.result = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:database.managedObjectContext sectionNameKeyPath:nil cacheName:nil];
	}
	else {
		NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"InvCategory"];
		request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"categoryName" ascending:YES]];

		if (self.filter == NCDatabaseFilterPublished)
			request.predicate = [NSPredicate predicateWithFormat:@"published == TRUE"];
		else if (self.filter == NCDatabaseFilterUnpublished)
			request.predicate = [NSPredicate predicateWithFormat:@"published == FALSE"];

		NCDatabase* database = [NCDatabase sharedDatabase];
		self.result = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:database.managedObjectContext sectionNameKeyPath:nil cacheName:nil];
	}
	NSError* error = nil;
	[self.result performFetch:&error];
	[self.tableView reloadData];
}

@end
