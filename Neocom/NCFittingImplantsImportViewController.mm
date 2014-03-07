//
//  NCFittingImplantsImportViewController.m
//  Neocom
//
//  Created by Shimanski Artem on 08.02.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCFittingImplantsImportViewController.h"
#import "NCTableViewCell.h"
#import "NCShipFit.h"
#import "NCStorage.h"
#import "NSArray+Neocom.h"
#import "NCFittingImplantsImportCell.h"

@interface NCFittingImplantsImportViewControllerRow : NSObject
@property (nonatomic, strong) NCLoadout* loadout;
@property (nonatomic, strong) NSString* description;
@end

@implementation NCFittingImplantsImportViewControllerRow

@end

@interface NCFittingImplantsImportViewController ()
@property (nonatomic, strong) NSArray* sections;

@end

@implementation NCFittingImplantsImportViewController

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
											 [storage.managedObjectContext performBlockAndWait:^{
												 NSArray* shipLoadouts = [[NCLoadout shipLoadouts] sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"type.typeName" ascending:YES]]];
												 NSMutableArray* rows = [NSMutableArray new];
												 for (NCLoadout* loadout in shipLoadouts) {
													 NCFittingImplantsImportViewControllerRow* row = [NCFittingImplantsImportViewControllerRow new];
													 row.loadout = loadout;
													 NSMutableArray* implants = [NSMutableArray new];
													 for (NCLoadoutDataShipImplant* implant in [(NCLoadoutDataShip*) loadout.data.data implants]) {
														 EVEDBInvType* type = [EVEDBInvType invTypeWithTypeID:implant.typeID error:nil];
														 if (type.typeName)
															 [implants addObject:type.typeName];
													 }
													 row.description = [implants componentsJoinedByString:@", "];
													 [rows addObject:row];
												 }
												 
												 task.progress = 0.25;
												 
												 [sections addObjectsFromArray:[rows arrayGroupedByKey:@"loadout.type.groupID"]];
												 task.progress = 0.5;
												 [sections sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
													 NCFittingImplantsImportViewControllerRow* a = [obj1 objectAtIndex:0];
													 NCFittingImplantsImportViewControllerRow* b = [obj2 objectAtIndex:0];
													 return [a.loadout.type.group.groupName compare:b.loadout.type.group.groupName];
												 }];
												 
												 task.progress = 1.0;
											 }];
										 }
							 completionHandler:^(NCTask *task) {
								 self.sections = sections;
								 [self.tableView reloadData];
								 
							 }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	if ([segue.identifier isEqualToString:@"Unwind"]) {
		NCFittingImplantsImportViewControllerRow* row = [sender object];
		NCShipFit* fit = [[NCShipFit alloc] initWithLoadout:row.loadout];
		self.selectedFit = fit;
	}
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.sections[section] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	NCFittingImplantsImportCell* cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
	NCFittingImplantsImportViewControllerRow* row = self.sections[indexPath.section][indexPath.row];
	cell.titleLabel.text = row.loadout.type.typeName;
	cell.implantsLabel.text = row.description;
	cell.typeImageView.image = [UIImage imageNamed:row.loadout.type.typeSmallImageName];
	cell.object = row;
	cell.accessoryView = nil;
	return cell;
}

- (NSString*) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	NCFittingImplantsImportViewControllerRow* row = self.sections[section][0];
	return row.loadout.type.group.groupName;
}

#pragma mark - Table view delegate

- (CGFloat) tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return 44;
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell* cell = [self tableView:tableView cellForRowAtIndexPath:indexPath];
	cell.bounds = CGRectMake(0, 0, CGRectGetWidth(tableView.bounds), CGRectGetHeight(cell.bounds));
	[cell setNeedsLayout];
	[cell layoutIfNeeded];
	return [cell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height + 1.0;
}

#pragma mark - NCTableViewController

- (NSString*) recordID {
	return nil;
}

- (id) identifierForSection:(NSInteger)section {
	NCFittingImplantsImportViewControllerRow* row = self.sections[section][0];
	return @(row.loadout.type.groupID);
}

@end
