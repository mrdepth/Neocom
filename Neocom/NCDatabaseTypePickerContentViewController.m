//
//  NCDatabaseTypePickerContentViewController.m
//  Neocom
//
//  Created by Shimanski Artem on 28.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCDatabaseTypePickerContentViewController.h"
#import "NCDatabaseTypePickerViewController.h"
#import "NCTableViewCell.h"
#import "NCDatabaseTypeInfoViewController.h"

@interface NCDatabaseTypePickerViewController ()
@property (nonatomic, copy) void (^completionHandler)(NCDBInvType* type);
@property (nonatomic, strong) NCDBEufeItemCategory* category;

@end

@interface NCDatabaseTypePickerContentViewController ()
@property (nonatomic, strong) NSFetchedResultsController* result;
@property (nonatomic, strong) NSFetchedResultsController* searchResult;

@end

@implementation NCDatabaseTypePickerContentViewController

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
	// Do any additional setup after loading the view.
}

- (void) dealloc {
	//[self.searchDisplayController.searchBar removeFromSuperview]; //Avoid crash
}

- (void) viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	if (!self.result)
		[self reload];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	if ([segue.identifier isEqualToString:@"NCDatabaseTypePickerContentViewController"]) {
		NCDatabaseTypePickerContentViewController* destinationViewController = segue.destinationViewController;
		NCDBEufeItemGroup* group = [sender object];
		destinationViewController.group = group;
		
		destinationViewController.title = group.groupName;
	}
	else if ([segue.identifier isEqualToString:@"NCDatabaseTypeInfoViewController"]) {
		NCDatabaseTypeInfoViewController* controller;
		if ([segue.destinationViewController isKindOfClass:[UINavigationController class]])
			controller = [segue.destinationViewController viewControllers][0];
		else
			controller = segue.destinationViewController;
		NCDBEufeItem* item = [sender object];
		controller.type = item.type;
	}
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return tableView == self.tableView ? self.result.sections.count : self.searchResult.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	id <NSFetchedResultsSectionInfo> sectionInfo = tableView == self.tableView ? self.result.sections[section] : self.searchResult.sections[section];
	return sectionInfo.numberOfObjects;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	id <NSFetchedResultsSectionInfo> sectionInfo = tableView == self.tableView  ? self.result.sections[indexPath.section] : self.searchResult.sections[indexPath.section];
	id row = sectionInfo.objects[indexPath.row];
	
	NCTableViewCell *cell = nil;
	if ([row isKindOfClass:[NCDBEufeItem class]]) {
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
	if ([row isKindOfClass:[NCDBEufeItem class]])
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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	id <NSFetchedResultsSectionInfo> sectionInfo = tableView == self.tableView  ? self.result.sections[indexPath.section] : self.searchResult.sections[indexPath.section];
	id row = sectionInfo.objects[indexPath.row];

	if ([row isKindOfClass:[NCDBEufeItem class]]) {
		NCDBEufeItem* item = row;
		NCDatabaseTypePickerViewController* navigationController = (NCDatabaseTypePickerViewController*) self.navigationController;
		navigationController.completionHandler(item.type);
	}
}

#pragma mark - NCTableViewController

- (NSString*) recordID {
	return nil;
}

- (void) searchWithSearchString:(NSString*) searchString {
	if (searchString.length > 1) {
		NCDatabaseTypePickerViewController* navigationController = (NCDatabaseTypePickerViewController*) self.navigationController;
		NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"EufeItem"];
		request.sortDescriptors = @[
									[NSSortDescriptor sortDescriptorWithKey:@"type.metaGroup.metaGroupID" ascending:YES],
									[NSSortDescriptor sortDescriptorWithKey:@"type.metaLevel" ascending:YES],
									[NSSortDescriptor sortDescriptorWithKey:@"type.typeName" ascending:YES]];
		
		request.predicate = [NSPredicate predicateWithFormat:@"ANY groups.category == %@ AND type.typeName CONTAINS[C] %@", navigationController.category, searchString];
		
		NCDatabase* database = [NCDatabase sharedDatabase];
		self.searchResult = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:database.managedObjectContext sectionNameKeyPath:@"type.metaGroupName" cacheName:nil];
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
	if ([row isKindOfClass:[NCDBEufeItem class]]) {
		NCDBEufeItem* item = row;
		cell.titleLabel.text = item.type.typeName;
		cell.iconView.image = item.type.icon.image.image;
		cell.object = row;
		if (!cell.iconView.image)
			cell.iconView.image = [[[NCDBEveIcon defaultTypeIcon] image] image];
	}
	else {
		if ([row isKindOfClass:[NCDBEufeItemGroup class]]) {
			NCDBEufeItemGroup* group = row;
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
	NSFetchRequest* request;
	NCDatabase* database = [NCDatabase sharedDatabase];

	request = [NSFetchRequest fetchRequestWithEntityName:@"EufeItem"];
	request.sortDescriptors = @[
								[NSSortDescriptor sortDescriptorWithKey:@"type.metaGroup.metaGroupID" ascending:YES],
								[NSSortDescriptor sortDescriptorWithKey:@"type.metaLevel" ascending:YES],
								[NSSortDescriptor sortDescriptorWithKey:@"type.typeName" ascending:YES]];
	
	request.predicate = [NSPredicate predicateWithFormat:@"ANY groups == %@", self.group];
	
	self.result = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:database.managedObjectContext sectionNameKeyPath:@"type.metaGroupName" cacheName:nil];
	[self.result performFetch:nil];

	if (self.result.fetchedObjects.count == 0) {
		NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"EufeItemGroup"];
		request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"groupName" ascending:YES]];
		
		request.predicate = [NSPredicate predicateWithFormat:@"parentGroup == %@", self.group];
		
		NCDatabase* database = [NCDatabase sharedDatabase];
		self.result = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:database.managedObjectContext sectionNameKeyPath:nil cacheName:nil];
		[self.result performFetch:nil];
	}
	[self.tableView reloadData];
}

@end
