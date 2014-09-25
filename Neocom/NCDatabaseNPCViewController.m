//
//  NCDatabaseNPCViewController.m
//  Neocom
//
//  Created by Артем Шиманский on 27.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCDatabaseNPCViewController.h"
#import "NCDatabaseTypeInfoViewController.h"
#import "NCTableViewCell.h"

@interface NCDatabaseNPCViewController ()
@property (nonatomic, strong) NSFetchedResultsController* result;
@property (nonatomic, strong) NSFetchedResultsController* searchResult;
- (void) reload;
@end

@implementation NCDatabaseNPCViewController

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
	if (self.npcGroup)
		self.title = self.npcGroup.npcGroupName;
	self.refreshControl = nil;
	[self reload];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	id row = [sender object];
	if ([segue.identifier isEqualToString:@"NCDatabaseNPCViewController"]) {
		NCDatabaseNPCViewController* destinationViewController = segue.destinationViewController;
		destinationViewController.npcGroup = row;
	}
	else if ([segue.identifier isEqualToString:@"NCDatabaseTypeInfoViewController"]) {
		NCDatabaseTypeInfoViewController* controller;
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
    return 1;
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
		static NSString *CellIdentifier = @"NpcGroupCell";
		cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
		if (!cell)
			cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	}
	[self tableView:tableView configureCell:cell forRowAtIndexPath:indexPath];
	return cell;
}

#pragma mark - Table view delegate

- (CGFloat) tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return 37;
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_6_1)
		return [self tableView:tableView estimatedHeightForRowAtIndexPath:indexPath];
	if (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_7_1)
		return UITableViewAutomaticDimension;

	id <NSFetchedResultsSectionInfo> sectionInfo = tableView == self.tableView  ? self.result.sections[indexPath.section] : self.searchResult.sections[indexPath.section];
	id row = sectionInfo.objects[indexPath.row];
	NCTableViewCell *cell;
	if ([row isKindOfClass:[NCDBInvType class]])
		cell = [self tableView:tableView offscreenCellWithIdentifier:@"TypeCell"];
	else
		cell = [self tableView:tableView offscreenCellWithIdentifier:@"NpcGroupCell"];
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
	NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"InvType"];
	request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"typeName" ascending:YES]];
	
	request.predicate = [NSPredicate predicateWithFormat:@"group.category.categoryID == 11 AND typeName CONTAINS[C] %@", searchString];
	
	NCDatabase* database = [NCDatabase sharedDatabase];
	request.fetchBatchSize = 50;
	self.searchResult = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:database.managedObjectContext sectionNameKeyPath:nil cacheName:nil];
	[self.searchResult performFetch:nil];
	[self.searchDisplayController.searchResultsTableView reloadData];
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
		NCDBNpcGroup* npcGroup = row;
		cell.titleLabel.text = npcGroup.npcGroupName;
		
		cell.iconView.image = npcGroup.icon ? npcGroup.icon.image.image : [[[NCDBEveIcon defaultGroupIcon] image] image];
		cell.object = row;
	}
}

#pragma mark - Private

- (void) reload {
	NCDatabase* database = [NCDatabase sharedDatabase];
	if (self.npcGroup) {
		if (self.npcGroup.group) {
			NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"InvType"];
			request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"typeName" ascending:YES]];
			request.predicate = [NSPredicate predicateWithFormat:@"group == %@", self.npcGroup.group];
			self.result = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:database.managedObjectContext sectionNameKeyPath:nil cacheName:nil];
			[self.result performFetch:nil];
		}
		else {
			NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"NpcGroup"];
			request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"npcGroupName" ascending:YES]];
			request.predicate = [NSPredicate predicateWithFormat:@"parentNpcGroup == %@", self.npcGroup];
			self.result = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:database.managedObjectContext sectionNameKeyPath:nil cacheName:nil];
			[self.result performFetch:nil];
		}
	}
	else {
		NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"NpcGroup"];
		request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"npcGroupName" ascending:YES]];
		request.predicate = [NSPredicate predicateWithFormat:@"parentNpcGroup == NULL"];
		self.result = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:database.managedObjectContext sectionNameKeyPath:nil cacheName:nil];
		[self.result performFetch:nil];
	}
}

@end
