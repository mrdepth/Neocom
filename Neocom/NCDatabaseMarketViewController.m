//
//  NCDatabaseMarketViewController.m
//  Neocom
//
//  Created by Shimanski Artem on 18.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCDatabaseMarketViewController.h"
#import "NCDatabaseTypeMarketInfoViewController.h"
#import "NCTableViewCell.h"

@interface NCDatabaseMarketViewController ()
@property (nonatomic, strong) NSFetchedResultsController* result;
@property (nonatomic, strong) NSFetchedResultsController* searchResult;

- (void) reload;
@end

@implementation NCDatabaseMarketViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	self.refreshControl = nil;
	if (self.marketGroup)
		self.title = self.marketGroup.marketGroupName;
	[self reload];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	id row = [sender object];
	if ([segue.identifier isEqualToString:@"NCDatabaseMarketViewController"]) {
		NCDatabaseMarketViewController* destinationViewController = segue.destinationViewController;
		destinationViewController.marketGroup = row;
	}
	else {
		NCDatabaseTypeMarketInfoViewController* controller;
		if ([segue.destinationViewController isKindOfClass:[UINavigationController class]])
			controller = [segue.destinationViewController viewControllers][0];
		else
			controller = segue.destinationViewController;

		controller.type = row;
	}
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
	NCTableViewCell *cell;
	if ([row isKindOfClass:[NCDBInvType class]]) {
		static NSString *CellIdentifier = @"TypeCell";
		cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
		if (!cell)
			cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	}
	else {
		static NSString *CellIdentifier = @"MarketGroupCell";
		cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
		if (!cell)
			cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	}
	[self tableView:tableView configureCell:cell forRowAtIndexPath:indexPath];
	return cell;
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
	
	id <NSFetchedResultsSectionInfo> sectionInfo = tableView == self.tableView  ? self.result.sections[indexPath.section] : self.searchResult.sections[indexPath.section];
	id row = sectionInfo.objects[indexPath.row];
	
	NCTableViewCell *cell = nil;
	if ([row isKindOfClass:[NCDBInvType class]])
		cell = [self tableView:self.tableView offscreenCellWithIdentifier:@"TypeCell"];
	else
		cell = [self tableView:self.tableView offscreenCellWithIdentifier:@"MarketGroupCell"];
	
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
		NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"InvType"];
		request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"typeName" ascending:YES]];
		request.predicate = [NSPredicate predicateWithFormat:@"marketGroup <> NULL AND published == TRUE AND typeName CONTAINS[C] %@", searchString];
		
		NCDatabase* database = [NCDatabase sharedDatabase];
		request.fetchBatchSize = 50;
		self.searchResult = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:database.managedObjectContext sectionNameKeyPath:nil cacheName:nil];

		NSError* error = nil;
		[self.searchResult performFetch:&error];
		[self.searchDisplayController.searchResultsTableView reloadData];
	}
	else {
		self.searchResult = nil;
		[self.searchDisplayController.searchResultsTableView reloadData];
	}
}

- (void) tableView:(UITableView *)tableView configureCell:(UITableViewCell*) tableViewCell forRowAtIndexPath:(NSIndexPath*) indexPath {
	id <NSFetchedResultsSectionInfo> sectionInfo = tableView == self.tableView ? self.result.sections[indexPath.section] : self.searchResult.sections[indexPath.section];
	id row = sectionInfo.objects[indexPath.row];

	NCTableViewCell *cell = (NCTableViewCell*) tableViewCell;
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
			NCDBInvMarketGroup* marketGroup = row;
			cell.titleLabel.text = marketGroup.marketGroupName;
			cell.iconView.image = marketGroup.icon.image.image;
		}
		
		cell.object = row;
	}
	
	if (!cell.iconView.image)
		cell.iconView.image = [[[NCDBEveIcon defaultGroupIcon] image] image];
}

#pragma mark - Private

- (void) reload {
	NSError* error = nil;

	if (self.marketGroup) {
		NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"InvMarketGroup"];
		request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"marketGroupName" ascending:YES]];
		request.predicate = [NSPredicate predicateWithFormat:@"parentGroup == %@", self.marketGroup];
		
		NCDatabase* database = [NCDatabase sharedDatabase];
		self.result = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:database.managedObjectContext sectionNameKeyPath:nil cacheName:nil];
		[self.result performFetch:&error];
		if (self.result.fetchedObjects.count == 0) {
			NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"InvType"];
			request.sortDescriptors = @[
										[NSSortDescriptor sortDescriptorWithKey:@"metaGroup.metaGroupID" ascending:YES],
										[NSSortDescriptor sortDescriptorWithKey:@"metaLevel" ascending:YES],
										[NSSortDescriptor sortDescriptorWithKey:@"typeName" ascending:YES]];
			request.predicate = [NSPredicate predicateWithFormat:@"marketGroup == %@ AND published == TRUE", self.marketGroup];
			self.result = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:database.managedObjectContext sectionNameKeyPath:@"metaGroupName" cacheName:nil];
			[self.result performFetch:&error];
		}
	}
	else {
		NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"InvMarketGroup"];
		request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"marketGroupName" ascending:YES]];
		request.predicate = [NSPredicate predicateWithFormat:@"parentGroup == NULL"];
		NCDatabase* database = [NCDatabase sharedDatabase];
		self.result = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:database.managedObjectContext sectionNameKeyPath:nil cacheName:nil];
		[self.result performFetch:&error];
	}
}

@end
