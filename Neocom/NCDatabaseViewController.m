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
@property (nonatomic, strong) NSArray* rows;
@property (nonatomic, strong) NSArray* searchResults;
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
	id <NSFetchedResultsSectionInfo> sectionInfo = tableView == self.tableView  ? self.result.sections[indexPath.section] : self.searchResult.sections[indexPath.section];
	id row = sectionInfo.objects[indexPath.row];
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
	
	id row = tableView == self.tableView ? self.rows[indexPath.row] : self.searchResults[indexPath.row];
	NSString *CellIdentifier;
	if ([row isKindOfClass:[EVEDBInvType class]])
		CellIdentifier = @"TypeCell";
	else
		CellIdentifier = @"CategoryGroupCell";
	
	UITableViewCell* cell = [self tableView:self.tableView offscreenCellWithIdentifier:CellIdentifier];
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
	if (searchString.length >= 2) {
		if (self.group) {
			NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"InvType"];
			request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"typeName" ascending:YES]];
			request.predicate = [NSPredicate predicateWithFormat:@"group == %@ AND typeName LIKE[C] %@", self.group, searchString];
			NCDatabase* database = [NCDatabase sharedDatabase];
			request.fetchBatchSize = 50;
			self.searchResult = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:database.managedObjectContext sectionNameKeyPath:nil cacheName:nil];
		}
		else if (self.category) {
			NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"InvType"];
			request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"typeName" ascending:YES]];
			request.predicate = [NSPredicate predicateWithFormat:@"group.category == %@ AND typeName LIKE[C] %@", self.category, searchString];
			NCDatabase* database = [NCDatabase sharedDatabase];
			request.fetchBatchSize = 50;
			self.searchResult = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:database.managedObjectContext sectionNameKeyPath:nil cacheName:nil];
		}
		else {
			NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"InvType"];
			request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"typeName" ascending:YES]];
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

	
/*	NSMutableArray* searchResults = [NSMutableArray new];
	[[self taskManager] addTaskWithIndentifier:NCTaskManagerIdentifierAuto
										 title:nil
										 block:^(NCTask *task) {
											 if ([task isCancelled])
												 return;
											 if (searchString.length >= 2) {
												 void (^block)(sqlite3_stmt* stmt, BOOL *needsMore) = ^(sqlite3_stmt* stmt, BOOL *needsMore) {
													 [searchResults addObject:[[EVEDBInvType alloc] initWithStatement:stmt]];
													 if ([task isCancelled])
														 *needsMore = NO;
												 };
												 
												 if (self.group != nil)
													 [[EVEDBDatabase sharedDatabase] execSQLRequest:[NSString stringWithFormat:@"SELECT * FROM invTypes WHERE groupID=%d AND typeName LIKE \"%%%@%%\"%@ ORDER BY typeName;",
																									 self.group.groupID,
																									 searchString,
																									 self.filter == NCDatabaseFilterPublished ? @" AND published=1" :
																									 self.filter == NCDatabaseFilterUnpublished ? @" AND published=0" : @""]
																						resultBlock:block];
												 else if (self.category != nil)
													 [[EVEDBDatabase sharedDatabase] execSQLRequest:[NSString stringWithFormat:@"SELECT invTypes.* FROM invTypes, invGroups WHERE invGroups.categoryID=%d AND invTypes.groupID=invGroups.groupID AND typeName LIKE \"%%%@%%\"%@ ORDER BY typeName;",
																									 self.category.categoryID,
																									 searchString,
																									 self.filter == NCDatabaseFilterPublished ? @" AND invTypes.published=1" :
																									 self.filter == NCDatabaseFilterUnpublished ? @" AND invTypes.published=0" : @""]
																						resultBlock:block];
												 else
													 [[EVEDBDatabase sharedDatabase] execSQLRequest:[NSString stringWithFormat:@"SELECT * FROM invTypes WHERE typeName LIKE \"%%%@%%\"%@ ORDER BY typeName;",
																									 searchString,
																									 self.filter == NCDatabaseFilterPublished ? @" AND published=1" :
																									 self.filter == NCDatabaseFilterUnpublished ? @" AND published=0" : @""]
																						resultBlock:block];
											 }
										 }
							 completionHandler:^(NCTask *task) {
								 if (![task isCancelled]) {
									 self.searchResults = searchResults;
									 [self.searchDisplayController.searchResultsTableView reloadData];
								 }
							 }];*/
}

- (void) tableView:(UITableView *)tableView configureCell:(NCTableViewCell*) cell forRowAtIndexPath:(NSIndexPath*) indexPath {
	id <NSFetchedResultsSectionInfo> sectionInfo = tableView == self.tableView ? self.result.sections[indexPath.section] : self.searchResult.sections[indexPath.section];
	id row = sectionInfo.objects[indexPath.row];
	
	if ([row isKindOfClass:[NCDBInvType class]]) {
		NCDBInvType* type = row;
		cell.titleLabel.text = type.typeName;
		cell.iconView.image = type.icon.image.image;
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
		
/*		NSString* iconImageName = [row icon].iconImageName;
		if (iconImageName)
			cell.iconView.image = [UIImage imageNamed:iconImageName];
		else
			cell.iconView.image = [UIImage imageNamed:@"Icons/icon38_174.png"];*/
		cell.object = row;
	}
	if (!cell.iconView.image)
		cell.iconView.image = [[[NCDBEveIcon defaultIcon] image] image];
}

#pragma mark - Private

- (void) reload {
	if (self.group) {
		NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"InvType"];
		request.sortDescriptors = @[
									[NSSortDescriptor sortDescriptorWithKey:@"metaGroup.metaGroupID" ascending:YES],
									[NSSortDescriptor sortDescriptorWithKey:@"metaLevel" ascending:YES],
									[NSSortDescriptor sortDescriptorWithKey:@"typeName" ascending:YES]];
		request.predicate = [NSPredicate predicateWithFormat:@"group == %@", self.group];
		NCDatabase* database = [NCDatabase sharedDatabase];
		self.result = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:database.managedObjectContext sectionNameKeyPath:@"metaGroupName" cacheName:nil];
	}
	else if (self.category) {
		NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"InvGroup"];
		request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"groupName" ascending:YES]];
		request.predicate = [NSPredicate predicateWithFormat:@"category == %@", self.category];
		NCDatabase* database = [NCDatabase sharedDatabase];
		self.result = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:database.managedObjectContext sectionNameKeyPath:nil cacheName:nil];
	}
	else {
		NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"InvCategory"];
		request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"categoryName" ascending:YES]];
		NCDatabase* database = [NCDatabase sharedDatabase];
		self.result = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:database.managedObjectContext sectionNameKeyPath:nil cacheName:nil];
	}
	NSError* error = nil;
	[self.result performFetch:&error];
	[self.tableView reloadData];
	return;
	NSMutableArray* rows = [NSMutableArray new];
	
	[[self taskManager] addTaskWithIndentifier:NCTaskManagerIdentifierNone
										 title:NCTaskManagerDefaultTitle
										 block:^(NCTask *task) {
											 if (self.group) {
												 [[EVEDBDatabase sharedDatabase] execSQLRequest:[NSString stringWithFormat:@"SELECT * FROM invTypes WHERE groupID=%d%@ ORDER BY typeName;", self.group.groupID,
																								 self.filter == NCDatabaseFilterPublished ? @" AND published=1":
																								 self.filter == NCDatabaseFilterUnpublished ? @" AND published=0" : @""]
																					resultBlock:^(sqlite3_stmt *stmt, BOOL *needsMore) {
																						[rows addObject:[[EVEDBInvType alloc] initWithStatement:stmt]];
																						if ([task isCancelled])
																							*needsMore = NO;
																					}];
											 }
											 else if (self.category) {
												 [[EVEDBDatabase sharedDatabase] execSQLRequest:[NSString stringWithFormat:@"SELECT * FROM invGroups WHERE categoryID=%d%@ ORDER BY groupName;", self.category.categoryID,
																								 self.filter == NCDatabaseFilterPublished ? @" AND published=1":
																								 self.filter == NCDatabaseFilterUnpublished ? @" AND published=0" : @""]
																					resultBlock:^(sqlite3_stmt *stmt, BOOL *needsMore) {
																						[rows addObject:[[EVEDBInvGroup alloc] initWithStatement:stmt]];
																						if ([task isCancelled])
																							*needsMore = NO;
																					}];
											 }
											 else {
												 [[EVEDBDatabase sharedDatabase] execSQLRequest:[NSString stringWithFormat:@"SELECT * FROM invCategories %@ ORDER BY categoryName",
																								 self.filter == NCDatabaseFilterPublished ? @"WHERE published=1":
																								 self.filter == NCDatabaseFilterUnpublished ? @"WHERE published=0" : @""]
																					resultBlock:^(sqlite3_stmt *stmt, BOOL *needsMore) {
																						[rows addObject:[[EVEDBInvCategory alloc] initWithStatement:stmt]];
																						if ([task isCancelled])
																							*needsMore = NO;
																					}];
											 }
										 }
							 completionHandler:^(NCTask *task) {
								 self.rows = rows;
								 [self update];
							 }];
}
@end
