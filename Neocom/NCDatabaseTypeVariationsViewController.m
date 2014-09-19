//
//  NCDatabaseTypeVariationsViewController.m
//  Neocom
//
//  Created by Артем Шиманский on 16.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCDatabaseTypeVariationsViewController.h"
#import "NCDatabaseTypeInfoViewController.h"
#import "NCTableViewCell.h"

@interface NCDatabaseTypeVariationsViewController ()
@property (nonatomic, strong) NSFetchedResultsController* result;

@end

@implementation NCDatabaseTypeVariationsViewController

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
	
	NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"InvType"];
	request.sortDescriptors = @[
								[NSSortDescriptor sortDescriptorWithKey:@"metaGroup.metaGroupID" ascending:YES],
								[NSSortDescriptor sortDescriptorWithKey:@"metaLevel" ascending:YES],
								[NSSortDescriptor sortDescriptorWithKey:@"typeName" ascending:YES]];
	
	
	if (self.type.parentType)
		request.predicate = [NSPredicate predicateWithFormat:@"parentType == %@ OR SELF == %@", self.type.parentType, self.type];
	else
		request.predicate = [NSPredicate predicateWithFormat:@"parentType == %@ OR SELF == %@", self.type, self.type];

	NCDatabase* database = [NCDatabase sharedDatabase];
	self.result = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:database.managedObjectContext sectionNameKeyPath:@"metaGroupName" cacheName:nil];
	[self.result performFetch:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	if ([segue.identifier isEqualToString:@"NCDatabaseTypeInfoViewController"]) {
		NCDatabaseTypeInfoViewController* controller;
		if ([segue.destinationViewController isKindOfClass:[UINavigationController class]])
			controller = [segue.destinationViewController viewControllers][0];
		else
			controller = segue.destinationViewController;
		
		controller.type = [sender object];
	}
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.result.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	id <NSFetchedResultsSectionInfo> sectionInfo = self.result.sections[section];
    return sectionInfo.numberOfObjects;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString *CellIdentifier = @"Cell";
	NCTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if (!cell)
		cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	[self tableView:tableView configureCell:cell forRowAtIndexPath:indexPath];
	return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	id <NSFetchedResultsSectionInfo> sectionInfo = self.result.sections[section];
	return sectionInfo.name.length > 0 ? sectionInfo.name : nil;
}

#pragma mark - Table view delegate

- (CGFloat) tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return 37;
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_6_1)
		return [self tableView:tableView estimatedHeightForRowAtIndexPath:indexPath];
	
	UITableViewCell* cell = [self tableView:tableView offscreenCellWithIdentifier:@"Cell"];
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

- (void) tableView:(UITableView *)tableView configureCell:(UITableViewCell*) tableViewCell forRowAtIndexPath:(NSIndexPath*) indexPath {
	id <NSFetchedResultsSectionInfo> sectionInfo = self.result.sections[indexPath.section];
	NCDBInvType* row = sectionInfo.objects[indexPath.row];
	
	NCTableViewCell *cell = (NCTableViewCell*) tableViewCell;
	cell.titleLabel.text = [row typeName];
	cell.iconView.image = row.icon.image.image ? row.icon.image.image : [[[NCDBEveIcon defaultTypeIcon] image] image];
	cell.object = row;
}

@end
