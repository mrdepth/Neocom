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
	
	if (!self.rows) {
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
		if ([row isKindOfClass:[EVEDBInvCategory class]])
			destinationViewController.category = row;
		else if ([row isKindOfClass:[EVEDBInvGroup class]])
			destinationViewController.group = row;
		destinationViewController.filter = self.filter;
	}
	else {
		NCDatabaseTypeInfoViewController* destinationViewController = segue.destinationViewController;
		id row = [sender object];
		destinationViewController.type = row;
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
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return tableView == self.tableView ? self.rows.count : self.searchResults.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	id row = tableView == self.tableView ? self.rows[indexPath.row] : self.searchResults[indexPath.row];
	if ([row isKindOfClass:[EVEDBInvType class]]) {
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

#pragma mark - Table view delegate

- (CGFloat) tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return 42;
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	id row = tableView == self.tableView ? self.rows[indexPath.row] : self.searchResults[indexPath.row];
	NSString *CellIdentifier;
	if ([row isKindOfClass:[EVEDBInvType class]])
		CellIdentifier = @"TypeCell";
	else
		CellIdentifier = @"CategoryGroupCell";
	
	UITableViewCell* cell = [self tableView:self.tableView offscreenCellWithIdentifier:CellIdentifier];
	[self tableView:tableView configureCell:cell forRowAtIndexPath:indexPath];
	
	cell.bounds = CGRectMake(0, 0, CGRectGetWidth(tableView.bounds), CGRectGetHeight(cell.bounds));
	[cell setNeedsLayout];
	[cell layoutIfNeeded];
	return [cell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height + 1.0;
}

#pragma mark - NCTableViewController

- (NSString*) recordID {
	return nil;
}

- (void) searchWithSearchString:(NSString*) searchString {
	NSMutableArray* searchResults = [NSMutableArray new];
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
							 }];
}

- (void) tableView:(UITableView *)tableView configureCell:(NCTableViewCell*) cell forRowAtIndexPath:(NSIndexPath*) indexPath {
	id row = tableView == self.tableView ? self.rows[indexPath.row] : self.searchResults[indexPath.row];
	if ([row isKindOfClass:[EVEDBInvType class]]) {
		cell.titleLabel.text = [row typeName];
		cell.iconView.image = [UIImage imageNamed:[row typeSmallImageName]];
		cell.object = row;
	}
	else {
		if ([row isKindOfClass:[EVEDBInvCategory class]])
			cell.titleLabel.text = [row categoryName];
		else
			cell.titleLabel.text = [row groupName];
		
		NSString* iconImageName = [row icon].iconImageName;
		if (iconImageName)
			cell.iconView.image = [UIImage imageNamed:iconImageName];
		else
			cell.iconView.image = [UIImage imageNamed:@"Icons/icon38_174.png"];
		cell.object = row;
	}
}

#pragma mark - Private

- (void) reload {
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
								 [self.tableView reloadData];
							 }];
}
@end
