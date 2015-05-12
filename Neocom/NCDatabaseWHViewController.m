//
//  NCDatabaseWHViewController.m
//  Neocom
//
//  Created by Артем Шиманский on 16.04.15.
//  Copyright (c) 2015 Artem Shimanski. All rights reserved.
//

#import "NCDatabaseWHViewController.h"
#import "NCDatabaseTypeInfoViewController.h"
#import "NSNumberFormatter+Neocom.h"

@interface NCDatabaseWHViewControllerRow : NSObject
@property (nonatomic, strong) NCDBInvType* type;
@property (nonatomic, strong) NSString* details;
@end

@interface NCDatabaseWHViewControllerSection : NSObject
@property (nonatomic, strong) NSMutableArray* rows;
@property (nonatomic, strong) NSString* title;
@property (nonatomic, assign) NSInteger targetSystemClass;
@end

@implementation NCDatabaseWHViewControllerSection
@end

@implementation NCDatabaseWHViewControllerRow
@end

@interface NCDatabaseWHViewController()
@property (nonatomic, strong) NSFetchedResultsController* result;
@property (nonatomic, strong) NSFetchedResultsController* searchResult;
- (void) reload;
@end

@implementation NCDatabaseWHViewController

- (void)viewDidLoad {
	[super viewDidLoad];
	self.refreshControl = nil;
	if (!self.result)
		[self reload];
}

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	if ([segue.identifier isEqualToString:@"NCDatabaseTypeInfoViewController"]) {
		NCDatabaseTypeInfoViewController* controller;
		if ([segue.destinationViewController isKindOfClass:[UINavigationController class]])
			controller = [segue.destinationViewController viewControllers][0];
		else
			controller = segue.destinationViewController;
		
		id row = [sender object];
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
	id<NSFetchedResultsSectionInfo> sectionInfo = tableView == self.tableView ? self.result.sections[section] : self.searchResult.sections[section];
	return sectionInfo.numberOfObjects;
}

- (NSString*) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	id<NSFetchedResultsSectionInfo> sectionInfo = tableView == self.tableView ? self.result.sections[section] : self.searchResult.sections[section];
	return sectionInfo.name;
}

#pragma mark - NCTableViewController

- (NSString*) recordID {
	return nil;
}

- (void) searchWithSearchString:(NSString*) searchString {
	if (searchString.length >= 1) {
		NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"WhType"];
		request.predicate = [NSPredicate predicateWithFormat:@"type.typeName CONTAINS[C] %@", searchString];
		request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"targetSystemClass" ascending:YES],
									[NSSortDescriptor sortDescriptorWithKey:@"type.typeName" ascending:YES]];
		NSFetchedResultsController* controller = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:[[NCDatabase sharedDatabase] managedObjectContext] sectionNameKeyPath:@"targetSystemClassDisplayName" cacheName:nil];
		
		[controller performFetch:nil];
		self.searchResult = controller;
		[self.searchDisplayController.searchResultsTableView reloadData];
	}
	else {
		self.searchResult = nil;
		[self.searchDisplayController.searchResultsTableView reloadData];
	}
}

- (void) tableView:(UITableView *)tableView configureCell:(NCDefaultTableViewCell*) cell forRowAtIndexPath:(NSIndexPath*) indexPath {
	NCDBWhType* row = tableView == self.tableView ? [self.result objectAtIndexPath:indexPath] : [self.searchResult objectAtIndexPath:indexPath];
	
	cell.titleLabel.text = row.type.typeName;
	if (row.maxJumpMass > 0)
		cell.subtitleLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%@ / %@ kg", nil), [NSNumberFormatter neocomLocalizedStringFromNumber:@(row.maxJumpMass)], [NSNumberFormatter neocomLocalizedStringFromNumber:@(row.maxStableMass)]];
	else
		cell.subtitleLabel.text = nil;
//	cell.subtitleLabel.text = row.details;
	cell.iconView.image = row.type.icon ? row.type.icon.image.image : [[[NCDBEveIcon defaultTypeIcon] image] image];
	cell.object = row.type;
}

- (NSString*) tableView:(UITableView *)tableView cellIdentifierForRowAtIndexPath:(NSIndexPath *)indexPath {
	return @"Cell";
}

#pragma mark - Private

- (void) reload {
	NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"WhType"];
	request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"targetSystemClass" ascending:YES],
								[NSSortDescriptor sortDescriptorWithKey:@"type.typeName" ascending:YES]];
	NSFetchedResultsController* controller = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:[[NCDatabase sharedDatabase] managedObjectContext] sectionNameKeyPath:@"targetSystemClassDisplayName" cacheName:nil];
	
	[controller performFetch:nil];
	self.result = controller;
	[self.tableView reloadData];
}


@end
