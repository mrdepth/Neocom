//
//  NCFittingMenuViewController.m
//  Neocom
//
//  Created by Shimanski Artem on 27.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCFittingMenuViewController.h"
#import "NCTableViewCell.h"
#import "NCDatabaseTypePickerViewController.h"
#import "UIViewController+Neocom.h"
#import "NCStorage.h"
#import "NCShipFit.h"
#import "NCPOSFit.h"
#import "NSArray+Neocom.h"
#import "NCFittingShipViewController.h"
#import "NCFittingPOSViewController.h"
#import "NCFittingCharacterPickerViewController.h"

#define NCCategoryIDShip 6


@interface NCFittingMenuViewControllerRow : NSObject
@property (nonatomic, strong) NSManagedObjectID* loadoutID;
@property (nonatomic, assign) int32_t typeID;
@property (nonatomic, assign) NCDBInvType* type;
@property (nonatomic, strong) NSString* loadoutName;
@property (nonatomic, strong) NSString* typeName;
@property (nonatomic, strong) NSManagedObjectID* iconID;
@property (nonatomic, strong) NCDBEveIcon* icon;
@property (nonatomic, assign) NCLoadoutCategory category;

@end

@implementation NCFittingMenuViewControllerRow

@end

@interface NCFittingMenuViewController ()
@property (nonatomic, strong, readwrite) NCDatabaseTypePickerViewController* typePickerViewController;
@property (nonatomic, strong) NSMutableArray* sections;
@property (nonatomic, strong) NCDBEveIcon* defaultTypeIcon;
@end

@implementation NCFittingMenuViewController

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
	self.navigationItem.rightBarButtonItem = self.editButtonItem;
	self.defaultTypeIcon = [self.databaseManagedObjectContext defaultTypeIcon];
}

- (void) viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	[self reload];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	if ([segue.identifier isEqualToString:@"NCFittingShipViewController"]) {
		NCFittingShipViewController* destinationViewController = segue.destinationViewController;
		destinationViewController.fit = sender;
	}
	else if ([segue.identifier isEqualToString:@"NCFittingPOSViewController"]) {
		NCFittingPOSViewController* destinationViewController = segue.destinationViewController;
		destinationViewController.fit = sender;
	}
}

- (void) didChangeStorage {
	[self reload];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.sections.count + 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return section == 0 ? 4 : [(NSArray*) self.sections[section - 1] count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
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

- (UITableViewCellEditingStyle) tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
	return indexPath.section == 0 ? UITableViewCellEditingStyleNone : UITableViewCellEditingStyleDelete;
}

- (void) tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
	if (editingStyle == UITableViewCellEditingStyleDelete) {
		NSMutableArray* array = self.sections[indexPath.section - 1];
		NCLoadout* loadout = array[indexPath.row];
		[self.storageManagedObjectContext performBlock:^{
			[self.storageManagedObjectContext deleteObject:loadout];
			[self.storageManagedObjectContext save:nil];
		}];
		
		if (array.count == 1) {
			[self.sections removeObjectAtIndex:indexPath.section - 1];
			[tableView deleteSections:[NSIndexSet indexSetWithIndex:indexPath.section] withRowAnimation:UITableViewRowAnimationMiddle];
		}
		else {
			[array removeObjectAtIndex:indexPath.row];
			[tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationMiddle];
		}
	}
}

#pragma mark - Table view delegate

- (BOOL) tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath {
	return indexPath.section != 0;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	if (![NCStorage sharedStorage]) {
		[tableView deselectRowAtIndexPath:indexPath animated:YES];
		return;
	}
	
	UITableViewCell* cell = [tableView cellForRowAtIndexPath:indexPath];
	if (indexPath.section == 0) {
		if (indexPath.row == 1) {
			self.typePickerViewController.title = NSLocalizedString(@"Ships", nil);
			
			[self.typePickerViewController presentWithCategory:[self.databaseManagedObjectContext shipsCategory]
											  inViewController:self
													  fromRect:cell.bounds
														inView:cell
													  animated:YES
											 completionHandler:^(NCDBInvType *type) {
												 /*NCShipFit* fit = [[NCShipFit alloc] initWithType:type];
												 NCStorage* storage = [NCStorage sharedStorage];
												 [storage.managedObjectContext performBlockAndWait:^{
													 fit.loadout = [[NCLoadout alloc] initWithEntity:[NSEntityDescription entityForName:@"Loadout" inManagedObjectContext:storage.managedObjectContext] insertIntoManagedObjectContext:storage.managedObjectContext];
													 fit.loadout.data = [[NCLoadoutData alloc] initWithEntity:[NSEntityDescription entityForName:@"LoadoutData" inManagedObjectContext:storage.managedObjectContext] insertIntoManagedObjectContext:storage.managedObjectContext];
												 }];
												 
												 [self performSegueWithIdentifier:@"NCFittingShipViewController" sender:fit];*/
												 [self.typePickerViewController dismissAnimated];
											 }];
		}
		else if (indexPath.row == 2) {
			self.typePickerViewController.title = NSLocalizedString(@"Control Towers", nil);
			[self.typePickerViewController presentWithCategory:[self.databaseManagedObjectContext controlTowersCategory]
//										 presentWithConditions:@[@"invTypes.marketGroupID = 478"]
											  inViewController:self
													  fromRect:cell.bounds
														inView:cell
													  animated:YES
											 completionHandler:^(NCDBInvType *type) {
												 /*NCPOSFit* fit = [[NCPOSFit alloc] initWithType:type];
												 NCStorage* storage = [NCStorage sharedStorage];
												 fit.loadout = [[NCLoadout alloc] initWithEntity:[NSEntityDescription entityForName:@"Loadout" inManagedObjectContext:storage.managedObjectContext] insertIntoManagedObjectContext:storage.managedObjectContext];
												 fit.loadout.data = [[NCLoadoutData alloc] initWithEntity:[NSEntityDescription entityForName:@"LoadoutData" inManagedObjectContext:storage.managedObjectContext] insertIntoManagedObjectContext:storage.managedObjectContext];
												 
												 [self performSegueWithIdentifier:@"NCFittingPOSViewController" sender:fit];*/
												 [self.typePickerViewController dismissAnimated];
											 }];
		}
	}
	else {
		NCLoadout* loadout = self.sections[indexPath.section - 1][indexPath.row];
/*		if (loadout.category == NCLoadoutCategoryShip) {
			NCShipFit* fit = [[NCShipFit alloc] initWithLoadout:loadout];
			[self performSegueWithIdentifier:@"NCFittingShipViewController" sender:fit];
		}
		else {
			NCPOSFit* fit = [[NCPOSFit alloc] initWithLoadout:loadout];
			[self performSegueWithIdentifier:@"NCFittingPOSViewController" sender:fit];
		}*/
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


- (NSString*) tableView:(UITableView *)tableView cellIdentifierForRowAtIndexPath:(NSIndexPath *)indexPath {
	if (indexPath.section == 0)
		return [NSString stringWithFormat:@"MenuItem%ldCell", (long)indexPath.row];
	else
		return @"Cell";
}

- (void) tableView:(UITableView *)tableView configureCell:(UITableViewCell*) tableViewCell forRowAtIndexPath:(NSIndexPath*) indexPath {
	if (indexPath.section > 0) {
		NCDefaultTableViewCell *cell = (NCDefaultTableViewCell*) tableViewCell;
		NCFittingMenuViewControllerRow* row = self.sections[indexPath.section - 1][indexPath.row];
		if (!row.icon && row.iconID)
			row.icon = [self.databaseManagedObjectContext objectWithID:row.iconID];
		
		cell.titleLabel.text = row.typeName;
		cell.subtitleLabel.text = row.loadoutName;
		cell.iconView.image = row.icon ? row.icon.image.image : self.defaultTypeIcon.image.image;
	}
}


#pragma mark - Private

- (void) reload {
	[self.storageManagedObjectContext performBlock:^{
		NSMutableArray* loadouts = [NSMutableArray new];
		for (NCLoadout* loadout in [self.storageManagedObjectContext loadouts]) {
			NCFittingMenuViewControllerRow* row = [NCFittingMenuViewControllerRow new];
			row.loadoutID = [loadout objectID];
			row.loadoutName = loadout.name;
			row.typeID = loadout.typeID;
			[loadouts addObject:row];
		};
		NSManagedObjectContext* databaseManagedObjectContext = [[NCDatabase sharedDatabase] createManagedObjectContextWithConcurrencyType:NSPrivateQueueConcurrencyType];
		[databaseManagedObjectContext performBlock:^{
			NSMutableArray* shipLoadouts = [NSMutableArray new];
			NSMutableArray* posLoadouts = [NSMutableArray new];
			for (NCFittingMenuViewControllerRow* row in loadouts) {
				row.type = [databaseManagedObjectContext invTypeWithTypeID:row.typeID];
				row.typeName = row.type.typeName;
				row.iconID = [row.type.icon objectID];
				if (row.type && row.type.group.category.categoryID == NCCategoryIDShip) {
					row.category = NCLoadoutCategoryShip;
					[shipLoadouts addObject:row];
				}
				else if (row.type) {
					row.category = NCLoadoutCategoryPOS;
					[posLoadouts addObject:row];
				}
			}
			[shipLoadouts sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"type.typeName" ascending:YES]]];
			[posLoadouts sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"type.typeName" ascending:YES]]];
			
			NSMutableArray* sections = [NSMutableArray new];
			for (NSArray* array in [shipLoadouts arrayGroupedByKey:@"type.group.groupID"])
				[sections addObject:[array mutableCopy]];

			[sections sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
				NCFittingMenuViewControllerRow* a = obj1[0];
				NCFittingMenuViewControllerRow* b = obj2[0];
				return [a.type.group.groupName compare:b.type.group.groupName];
			}];

			if (posLoadouts.count > 0)
				[sections addObject:[posLoadouts mutableCopy]];
			[loadouts setValue:nil forKey:@"type"];
			
			dispatch_async(dispatch_get_main_queue(), ^{
				self.sections = sections;
				[self.tableView reloadData];
			});
		}];
	}];
	
/*	[[self taskManager] addTaskWithIndentifier:NCTaskManagerIdentifierAuto
										 title:NCTaskManagerDefaultTitle
										 block:^(NCTask *task) {
											 NCStorage* storage = [NCStorage sharedStorage];
											 NSManagedObjectContext* context = [NSThread isMainThread] ? storage.managedObjectContext : storage.backgroundManagedObjectContext;
											 [context performBlockAndWait:^{
												 NSArray* shipLoadouts = [[storage shipLoadouts] sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"type.typeName" ascending:YES]]];
												 task.progress = 0.25;
												 
												 for (NSArray* array in [shipLoadouts arrayGroupedByKey:@"type.group.groupID"])
													 [sections addObject:[array mutableCopy]];
												 
												 task.progress = 0.5;
												 [sections sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
													 NCLoadout* a = [obj1 objectAtIndex:0];
													 NCLoadout* b = [obj2 objectAtIndex:0];
													 return [a.type.group.groupName compare:b.type.group.groupName];
												 }];
												 
												 task.progress = 0.75;
												 
												 NSArray* posLoadouts = [[storage posLoadouts] sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"type.typeName" ascending:YES]]];
												 if (posLoadouts.count > 0)
													 [sections addObject:[posLoadouts mutableCopy]];
												 
												 task.progress = 1.0;
											 }];
										 }
							 completionHandler:^(NCTask *task) {
								 self.sections = sections;
								 [self update];
								 
							 }];*/
}

- (NCDatabaseTypePickerViewController*) typePickerViewController {
	if (!_typePickerViewController) {
		_typePickerViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"NCDatabaseTypePickerViewController"];
	}
	return _typePickerViewController;
}

- (id) identifierForSection:(NSInteger)section {
	if (section > 0) {
		NSArray* rows = self.sections[section - 1];
		if (rows.count > 0)
			return [rows[0] valueForKeyPath:@"type.group.groupID"];
	}
	return nil;
}

@end
