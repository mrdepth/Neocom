//
//  NCFittingFitPickerViewController.m
//  Neocom
//
//  Created by Артем Шиманский on 03.02.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCFittingFitPickerViewController.h"
#import "NCDatabaseTypePickerViewController.h"
#import "NCTableViewCell.h"
#import "NCLoadout.h"
#import "NCShipFit.h"
#import "NCStorage.h"
#import "NSArray+Neocom.h"

@interface NCFittingFitPickerViewController ()
@property (nonatomic, strong) NSArray* sections;
@end

@implementation NCFittingFitPickerViewController


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

	NSMutableArray* sections = [NSMutableArray new];
	[[self taskManager] addTaskWithIndentifier:NCTaskManagerIdentifierAuto
										 title:NCTaskManagerDefaultTitle
										 block:^(NCTask *task) {
											 NCStorage* storage = [NCStorage sharedStorage];
											 NSManagedObjectContext* context = [NSThread isMainThread] ? storage.managedObjectContext : storage.backgroundManagedObjectContext;
											 [context performBlockAndWait:^{
												 NSArray* shipLoadouts = [[storage shipLoadouts] sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"type.typeName" ascending:YES]]];
												 task.progress = 0.25;
												 
												 [sections addObjectsFromArray:[shipLoadouts arrayGroupedByKey:@"type.group.groupID"]];
												 task.progress = 0.5;
												 [sections sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
													 NCLoadout* a = [obj1 objectAtIndex:0];
													 NCLoadout* b = [obj2 objectAtIndex:0];
													 return [a.type.group.groupName compare:b.type.group.groupName];
												 }];
												 
												 task.progress = 1.0;
											 }];
										 }
							 completionHandler:^(NCTask *task) {
								 self.sections = sections;
								 [self update];
								 
							 }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.sections.count + 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return section == 0 ? 1 : [(NSArray*) self.sections[section - 1] count];
}

- (NSString*) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	if (section == 0)
		return nil;
	else {
		NSArray* rows = self.sections[section - 1];
		if (rows.count > 0)
			return [rows[0] valueForKeyPath:@"type.group.groupName"];
		else
			return nil;
	}
}


#pragma mark - Table view delegate

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell* cell = [tableView cellForRowAtIndexPath:indexPath];
	if (indexPath.section == 0) {
		
		NCDatabaseTypePickerViewController* controller = [self.storyboard instantiateViewControllerWithIdentifier:@"NCDatabaseTypePickerViewController"];
		[controller presentWithCategory:[NCDBEufeItemCategory shipsCategory]
					   inViewController:self
							   fromRect:cell.bounds
								 inView:cell
							   animated:YES
					  completionHandler:^(NCDBInvType *type) {
						  NCShipFit* fit = [[NCShipFit alloc] initWithType:type];
						  NCStorage* storage = [NCStorage sharedStorage];
						  fit.loadout = [[NCLoadout alloc] initWithEntity:[NSEntityDescription entityForName:@"Loadout" inManagedObjectContext:storage.managedObjectContext] insertIntoManagedObjectContext:storage.managedObjectContext];
						  fit.loadout.data = [[NCLoadoutData alloc] initWithEntity:[NSEntityDescription entityForName:@"LoadoutData" inManagedObjectContext:storage.managedObjectContext] insertIntoManagedObjectContext:storage.managedObjectContext];
						  self.selectedFit = fit;
						  [self performSegueWithIdentifier:@"Unwind" sender:cell];
						  [self dismissAnimated];
					  }];
	}
	else {
		NCLoadout* loadout = self.sections[indexPath.section - 1][indexPath.row];
		NCShipFit* fit = [[NCShipFit alloc] initWithLoadout:loadout];
		self.selectedFit = fit;
		[self performSegueWithIdentifier:@"Unwind" sender:cell];
	}
}

#pragma mark - CollapsableTableViewDelegate

- (BOOL) tableView:(UITableView *)tableView canCollapsSection:(NSInteger) section {
	return section == 0 ? NO : [super tableView:tableView canCollapsSection:section];
}

#pragma mark - NCTableViewController

- (NSString*) recordID {
	return nil;
}

- (id) identifierForSection:(NSInteger)section {
	if (section > 0) {
		NSArray* rows = self.sections[section - 1];
		if (rows.count > 0)
			return [rows[0] valueForKeyPath:@"type.group.groupID"];
	}
	return nil;
}

- (NSString* )tableView:(UITableView *)tableView cellIdentifierForRowAtIndexPath:(NSIndexPath *)indexPath {
	if (indexPath.section == 0)
		return [NSString stringWithFormat:@"MenuItem%ldCell", (long)indexPath.row];
	else
		return @"Cell";
}

- (void) tableView:(UITableView *)tableView configureCell:(UITableViewCell *)tableViewCell forRowAtIndexPath:(NSIndexPath *)indexPath {
	if (indexPath.section == 0) {
	}
	else {
		NCDefaultTableViewCell *cell = (NCDefaultTableViewCell*) tableViewCell;
		NCLoadout* loadout = self.sections[indexPath.section - 1][indexPath.row];
		cell.titleLabel.text = loadout.type.typeName;
		cell.subtitleLabel.text = loadout.name;
		cell.iconView.image = loadout.type.icon ? loadout.type.icon.image.image : [[[NCDBEveIcon defaultTypeIcon] image] image];
	}
}

@end
