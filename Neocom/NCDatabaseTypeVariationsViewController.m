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
@property (nonatomic, strong) NCDBInvType* type;
@property (nonatomic, strong) NCDBEveIcon* defaultTypeIcon;

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
	self.type = (NCDBInvType*) [self.databaseManagedObjectContext objectWithID:self.typeID];
	self.defaultTypeIcon = [self.databaseManagedObjectContext defaultTypeIcon];

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

	self.result = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:self.databaseManagedObjectContext sectionNameKeyPath:@"metaGroupName" cacheName:nil];
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
		
		controller.typeID = [[sender object] objectID];
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

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	id <NSFetchedResultsSectionInfo> sectionInfo = self.result.sections[section];
	return sectionInfo.name.length > 0 ? sectionInfo.name : nil;
}

#pragma mark - NCTableViewController

- (NSString*) tableView:(UITableView *)tableView cellIdentifierForRowAtIndexPath:(NSIndexPath *)indexPath {
	return @"Cell";
}

- (void) tableView:(UITableView *)tableView configureCell:(UITableViewCell*) tableViewCell forRowAtIndexPath:(NSIndexPath*) indexPath {
	id <NSFetchedResultsSectionInfo> sectionInfo = self.result.sections[indexPath.section];
	NCDBInvType* row = sectionInfo.objects[indexPath.row];
	
	NCDefaultTableViewCell *cell = (NCDefaultTableViewCell*) tableViewCell;
	cell.titleLabel.text = [row typeName];
	cell.iconView.image = row.icon.image.image ? row.icon.image.image : self.defaultTypeIcon.image.image;
	cell.object = row;
}

@end
