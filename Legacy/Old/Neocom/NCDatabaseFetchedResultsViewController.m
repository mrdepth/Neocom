//
//  NCDatabaseFetchedResultsViewController.m
//  Neocom
//
//  Created by Артем Шиманский on 14.04.15.
//  Copyright (c) 2015 Artem Shimanski. All rights reserved.
//

#import "NCDatabaseFetchedResultsViewController.h"
#import "NCDatabase.h"
#import "NCDatabaseViewController.h"

@interface NCDatabaseFetchedResultsViewController()
@property (nonatomic, strong) NSFetchedResultsController* result;
@end

@implementation NCDatabaseFetchedResultsViewController

- (void)viewDidLoad {
	[super viewDidLoad];
	self.refreshControl = nil;
	self.result = [[NSFetchedResultsController alloc] initWithFetchRequest:self.request managedObjectContext:self.databaseManagedObjectContext sectionNameKeyPath:@"category.categoryName" cacheName:nil];
	[self.result performFetch:nil];
}



- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	if ([segue.identifier isEqualToString:@"NCDatabaseViewController"]) {
		NCDatabaseViewController* controller;
		if ([segue.destinationViewController isKindOfClass:[UINavigationController class]])
			controller = [segue.destinationViewController viewControllers][0];
		else
			controller = segue.destinationViewController;
		
		id row = [sender object];
		controller.group = row;
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

- (NSString*) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	id <NSFetchedResultsSectionInfo> sectionInfo = self.result.sections[section];
	return sectionInfo.name.length > 0 ? sectionInfo.name : nil;
}

#pragma mark - NCTableViewController

- (void) tableView:(UITableView *)tableView configureCell:(NCDefaultTableViewCell*) cell forRowAtIndexPath:(NSIndexPath*) indexPath {
	id row = [self.result objectAtIndexPath:indexPath];
	
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
		cell.iconView.image = [[[self.databaseManagedObjectContext defaultGroupIcon] image] image];
	cell.object = row;
}

- (NSString*) tableView:(UITableView *)tableView cellIdentifierForRowAtIndexPath:(NSIndexPath *)indexPath {
	return @"Cell";
}


@end
