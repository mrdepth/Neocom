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
	[[self taskManager] addTaskWithIndentifier:NCTaskManagerIdentifierAuto
										 title:NCTaskManagerDefaultTitle
										 block:^(NCTask *task) {
											 NCStorage* storage = [NCStorage sharedStorage];
											 NSManagedObjectContext* context = [NSThread isMainThread] ? storage.managedObjectContext : storage.backgroundManagedObjectContext;
											 NSMutableDictionary* types = [NSMutableDictionary new];
											 [context performBlockAndWait:^{
												 NSArray* sets = [storage implantSets];
												 for (NCImplantSet* set in sets) {
													 NSMutableArray* components = [NSMutableArray new];
													 NCImplantSetData* data = set.data;
													 NSMutableArray* ids = [NSMutableArray new];
													 if (data.implantIDs)
														 [ids addObjectsFromArray:data.implantIDs];
													 if (data.boosterIDs)
														 [ids addObjectsFromArray:data.boosterIDs];
													 
													 for (NSNumber* typeID in ids) {
														 NCDBInvType* type = types[typeID];
														 if (!type) {
															 type = [NCDBInvType invTypeWithTypeID:[typeID intValue]];
															 if (type)
																 types[typeID] = type;
														 }
														 if (type.typeName)
															 [components addObject:type.typeName];
													 }
													 NCFittingImplantSetsViewControllerRow* row = [NCFittingImplantSetsViewControllerRow new];
													 row.implantSet = set;
													 row.description = [components componentsJoinedByString:@", "];
													 [rows addObject:row];
												 }
											 }];
										 }
							 completionHandler:^(NCTask *task) {
								 self.rows = rows;
								 [self update];
								 if (self.rows.count == 0 && self.saveMode)
									 [self saveNew];
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
		NCStorage* storage = [NCStorage sharedStorage];
		[storage.managedObjectContext performBlock:^{
			[storage.managedObjectContext deleteObject:row.implantSet];
			[storage saveContext];
		}];
		[self.rows removeObjectAtIndex:indexPath.row];
		[tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
	}
}

#pragma mark - Table view delegate

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	if (indexPath.section == 0) {
		NCFittingImplantSetsViewControllerRow* row = self.rows[indexPath.row];
		if (self.saveMode) {
			[[UIAlertView alertViewWithTitle:nil
									 message:[NSString stringWithFormat:NSLocalizedString(@"Replace Implant Set \"%@\"", nil), row.implantSet.name]
						   cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
						   otherButtonTitles:@[NSLocalizedString(@"Replace", nil)]
							 completionBlock:^(UIAlertView *alertView, NSInteger selectedButtonIndex) {
								 if (selectedButtonIndex != alertView.cancelButtonIndex) {
									 NCStorage* storage = [NCStorage sharedStorage];
									 NSManagedObjectContext* context = [NSThread isMainThread] ? storage.managedObjectContext : storage.backgroundManagedObjectContext;
									 [context performBlockAndWait:^{
										 row.implantSet.data = self.implantSetData;
										 [storage saveContext];
									 }];
									 [self performSegueWithIdentifier:@"Unwind" sender:nil];
								 }
							 }
								 cancelBlock:nil] show];
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
	UIAlertView* alertView = [UIAlertView alertViewWithTitle:nil
													 message:NSLocalizedString(@"Enter Implant Set name", nil)
										   cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
										   otherButtonTitles:@[NSLocalizedString(@"Save", nil)]
											 completionBlock:^(UIAlertView *alertView, NSInteger selectedButtonIndex) {
												 if (selectedButtonIndex != alertView.cancelButtonIndex) {
													 UITextField* textField = [alertView textFieldAtIndex:0];
													 NSString* name = textField.text;
													 if (name.length == 0)
														 name = NSLocalizedString(@"Unnamed", nil);
													 NCStorage* storage = [NCStorage sharedStorage];
													 NSManagedObjectContext* context = [NSThread isMainThread] ? storage.managedObjectContext : storage.backgroundManagedObjectContext;
													 [context performBlockAndWait:^{
														 NCImplantSet* implantSet = [[NCImplantSet alloc] initWithEntity:[NSEntityDescription entityForName:@"ImplantSet" inManagedObjectContext:storage.managedObjectContext]
																						  insertIntoManagedObjectContext:storage.managedObjectContext];
														 implantSet.name = name;
														 implantSet.data = self.implantSetData;
														 [storage saveContext];
													 }];
													 [self performSegueWithIdentifier:@"Unwind" sender:nil];
												 }
											 }
												 cancelBlock:nil];
	alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
	[alertView show];
}

@end
