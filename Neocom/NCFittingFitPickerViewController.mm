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

@interface NCFittingFitPickerViewControllerRow : NSObject
@property (nonatomic, strong) NSManagedObjectID* loadoutID;
@property (nonatomic, assign) int32_t typeID;
@property (nonatomic, strong) NSString* loadoutName;
@property (nonatomic, strong) NSString* typeName;
@property (nonatomic, strong) NSManagedObjectID* iconID;
@property (nonatomic, strong) NCDBEveIcon* icon;
@property (nonatomic, assign) NCLoadoutCategory category;

@end

@implementation NCFittingFitPickerViewControllerRow

@end

@interface NCFittingFitPickerViewControllerSection : NSObject
@property (nonatomic, strong) NSMutableArray* rows;
@property (nonatomic, assign) int32_t groupID;
@property (nonatomic, strong) NSString* title;
@end

@implementation NCFittingFitPickerViewControllerSection
@end

@interface NCFittingFitPickerViewController ()
@property (nonatomic, strong) NSArray* sections;
@property (nonatomic, strong) NCDBEveIcon* defaultTypeIcon;
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
	self.defaultTypeIcon = [self.databaseManagedObjectContext defaultTypeIcon];
	[self reload];
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
	return section == 0 ? 1 : [[(NCFittingFitPickerViewControllerSection*) self.sections[section - 1] rows] count];
}

- (NSString*) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)sectionIndex {
	if (sectionIndex == 0)
		return nil;
	else {
		NCFittingFitPickerViewControllerSection* section = self.sections[sectionIndex - 1];
		return section.title;
	}
}


#pragma mark - Table view delegate

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell* cell = [tableView cellForRowAtIndexPath:indexPath];
	if (indexPath.section == 0) {
		
		NCDatabaseTypePickerViewController* controller = [self.storyboard instantiateViewControllerWithIdentifier:@"NCDatabaseTypePickerViewController"];
		[controller presentWithCategory:[self.databaseManagedObjectContext shipsCategory]
					   inViewController:self
							   fromRect:cell.bounds
								 inView:cell
							   animated:YES
					  completionHandler:^(NCDBInvType *type) {
						  NCLoadout* loadout = [[NCLoadout alloc] initWithEntity:[NSEntityDescription entityForName:@"Loadout" inManagedObjectContext:self.storageManagedObjectContext] insertIntoManagedObjectContext:self.storageManagedObjectContext];
						  loadout.typeID = type.typeID;
						  loadout.name = type.typeName;
						  loadout.data = [[NCLoadoutData alloc] initWithEntity:[NSEntityDescription entityForName:@"LoadoutData" inManagedObjectContext:self.storageManagedObjectContext] insertIntoManagedObjectContext:self.storageManagedObjectContext];
						  NCShipFit* fit = [[NCShipFit alloc] initWithLoadout:loadout];
						  self.selectedFit = fit;
                          [controller dismissAnimated];
						  [self performSegueWithIdentifier:@"Unwind" sender:cell];
					  }];
	}
	else {
		NCFittingFitPickerViewControllerSection* section = self.sections[indexPath.section - 1];
		NCFittingFitPickerViewControllerRow* row = section.rows[indexPath.row];
		NCLoadout* loadout = [self.storageManagedObjectContext objectWithID:row.loadoutID];
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

- (id) identifierForSection:(NSInteger)sectionIndex {
	if (sectionIndex > 0) {
		NCFittingFitPickerViewControllerSection* section = self.sections[sectionIndex - 1];
		return @(section.groupID);
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
		NCFittingFitPickerViewControllerSection* section = self.sections[indexPath.section - 1];
		NCFittingFitPickerViewControllerRow* row = section.rows[indexPath.row];
		if (!row.icon && row.iconID)
			row.icon = [self.databaseManagedObjectContext objectWithID:row.iconID];
		
		cell.titleLabel.text = row.typeName;
		cell.subtitleLabel.text = row.loadoutName;
		cell.iconView.image = row.icon ? row.icon.image.image : self.defaultTypeIcon.image.image;
	}
}

- (void) reload {
	NSManagedObjectContext* storageManagedObjectContext = [[NCStorage sharedStorage] createManagedObjectContext];
	[storageManagedObjectContext performBlock:^{
		NSMutableArray* loadouts = [NSMutableArray new];
		for (NCLoadout* loadout in [storageManagedObjectContext loadouts]) {
			NCFittingFitPickerViewControllerRow* row = [NCFittingFitPickerViewControllerRow new];
			row.loadoutID = [loadout objectID];
			row.loadoutName = loadout.name;
			row.typeID = loadout.typeID;
			[loadouts addObject:row];
		};
		NSManagedObjectContext* databaseManagedObjectContext = [[NCDatabase sharedDatabase] createManagedObjectContextWithConcurrencyType:NSPrivateQueueConcurrencyType];
		[databaseManagedObjectContext performBlock:^{
			NSMutableDictionary* shipLoadouts = [NSMutableDictionary new];
			
			for (NCFittingFitPickerViewControllerRow* row in loadouts) {
				NCDBInvType* type = [databaseManagedObjectContext invTypeWithTypeID:row.typeID];
				row.typeName = type.typeName;
				row.iconID = [type.icon objectID];
				if (type && type.group.category.categoryID == NCCategoryIDShip) {
					row.category = NCLoadoutCategoryShip;
					NCFittingFitPickerViewControllerSection* section = shipLoadouts[@(type.group.groupID)];
					if (!section) {
						section = [NCFittingFitPickerViewControllerSection new];
						shipLoadouts[@(type.group.groupID)] = section;
						section.title = type.group.groupName;
						section.groupID = type.group.groupID;
						section.rows = [NSMutableArray new];
					}
					[section.rows addObject:row];
				}
			}
			NSMutableArray* sections = [[[shipLoadouts allValues] sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"title" ascending:YES]]] mutableCopy];
			
			
			for (NCFittingFitPickerViewControllerSection* section in sections)
				[section.rows sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"typeName" ascending:YES]]];

			dispatch_async(dispatch_get_main_queue(), ^{
				self.sections = sections;
				[self.tableView reloadData];
			});
		}];
	}];
}

@end
