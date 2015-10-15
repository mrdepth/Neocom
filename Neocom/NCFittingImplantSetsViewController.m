//
//  NCFittingImplantSetsViewController.m
//  Neocom
//
//  Created by Артем Шиманский on 24.03.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCFittingImplantSetsViewController.h"
#import "NCStorage.h"
#import "NCTableViewCell.h"
#import "UIAlertView+Block.h"

@interface NCFittingImplantSetsViewControllerRow : NSObject
@property (nonatomic, strong) NCImplantSet* implantSet;
@property (nonatomic, strong) NSString* description;
@end

@implementation NCFittingImplantSetsViewControllerRow
@synthesize description = _description;


@end

@interface NCFittingImplantSetsViewController ()
@property (nonatomic, strong) NSMutableArray* rows;
- (void) saveNew;
@end

@implementation NCFittingImplantSetsViewController

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
	self.navigationItem.rightBarButtonItem = self.editButtonItem;
	self.refreshControl = nil;
	
	NSMutableArray* rows = [NSMutableArray new];
	for (NCImplantSet* set in [self.storageManagedObjectContext implantSets]) {
		NSMutableArray* components = [NSMutableArray new];
		NCImplantSetData* data = set.data;
		NSMutableArray* ids = [NSMutableArray new];
		if (data.implantIDs)
			[ids addObjectsFromArray:data.implantIDs];
		if (data.boosterIDs)
			[ids addObjectsFromArray:data.boosterIDs];
		
		for (NSNumber* typeID in ids) {
			NCDBInvType* type = [self.databaseManagedObjectContext invTypeWithTypeID:[typeID intValue]];
			if (type.typeName)
				[components addObject:type.typeName];
		}
		NCFittingImplantSetsViewControllerRow* row = [NCFittingImplantSetsViewControllerRow new];
		row.implantSet = set;
		row.description = [components componentsJoinedByString:@", "];
		[rows addObject:row];
	}
	self.rows = rows;
	if (self.rows.count == 0 && self.saveMode)
		[self saveNew];
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	if ([segue.identifier isEqual:@"Unwind"]) {
		if ([self.storageManagedObjectContext hasChanges])
			[self.storageManagedObjectContext save:nil];
	}
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.saveMode ? 2 : 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return section == 0 ? self.rows.count : 1;
}

- (BOOL) tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
	return indexPath.section == 0;
}

- (void) tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
	if (editingStyle == UITableViewCellEditingStyleDelete) {
		NCFittingImplantSetsViewControllerRow* row = self.rows[indexPath.row];
		[self.storageManagedObjectContext deleteObject:row.implantSet];
		[self.rows removeObjectAtIndex:indexPath.row];
		[tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
	}
}

#pragma mark - Table view delegate

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	if (indexPath.section == 0) {
		NCFittingImplantSetsViewControllerRow* row = self.rows[indexPath.row];
		if (self.saveMode) {
			UIAlertController* controller = [UIAlertController alertControllerWithTitle:nil message:[NSString stringWithFormat:NSLocalizedString(@"Replace Implant Set \"%@\"", nil), row.implantSet.name] preferredStyle:UIAlertControllerStyleAlert];
			[controller addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Replace", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
				row.implantSet.data = self.implantSetData;
				[self performSegueWithIdentifier:@"Unwind" sender:nil];
			}]];
			[controller addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
			}]];
			[self presentViewController:controller animated:YES completion:nil];
		}
		else {
			self.selectedImplantSet = row.implantSet;
			[self performSegueWithIdentifier:@"Unwind" sender:[tableView cellForRowAtIndexPath:indexPath]];
		}
	}
	else {
		[self saveNew];
	}
}

#pragma mark - NCTableViewController

- (NSString*) recordID {
	return nil;
}

- (NSString*) tableView:(UITableView *)tableView cellIdentifierForRowAtIndexPath:(NSIndexPath *)indexPath {
	return @"Cell";
}

- (void) tableView:(UITableView *)tableView configureCell:(UITableViewCell *)tableViewCell forRowAtIndexPath:(NSIndexPath *)indexPath {
	NCDefaultTableViewCell* cell = (NCDefaultTableViewCell*) tableViewCell;
	if (indexPath.section == 0) {
		NCFittingImplantSetsViewControllerRow* row = self.rows[indexPath.row];
		cell.titleLabel.text = row.implantSet.name;
		cell.subtitleLabel.text = row.description;
		cell.object = row.implantSet;
	}
	else {
		cell.titleLabel.text = NSLocalizedString(@"New Implant Set", nil);
		cell.subtitleLabel.text = nil;
		cell.object = nil;
	}
}

#pragma mark - Private

- (void) saveNew {
	UIAlertController* controller = [UIAlertController alertControllerWithTitle:nil message:NSLocalizedString(@"Enter Implant Set name", nil) preferredStyle:UIAlertControllerStyleAlert];
	__block UITextField* nameTextField;
	[controller addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
		nameTextField = textField;
		textField.clearButtonMode = UITextFieldViewModeAlways;
	}];
	
	[controller addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Save", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
		NSString* name = nameTextField.text;
		if (name.length == 0)
			name = NSLocalizedString(@"Unnamed", nil);
		NCImplantSet* implantSet = [[NCImplantSet alloc] initWithEntity:[NSEntityDescription entityForName:@"ImplantSet" inManagedObjectContext:self.storageManagedObjectContext]
										 insertIntoManagedObjectContext:self.storageManagedObjectContext];
		implantSet.name = name;
		implantSet.data = self.implantSetData;
		[self performSegueWithIdentifier:@"Unwind" sender:nil];
	}]];
	
	[controller addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
	}]];
	[self presentViewController:controller animated:YES completion:nil];
}

@end
