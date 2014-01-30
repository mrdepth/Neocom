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

@interface NCFittingMenuViewController ()
@property (nonatomic, strong, readwrite) NCDatabaseTypePickerViewController* typePickerViewController;
@property (nonatomic, strong) NSArray* fits;
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
	// Do any additional setup after loading the view.
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
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.fits.count + 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return section == 0 ? 5 : [self.fits[section] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	if (indexPath.section == 0) {
		NSString *CellIdentifier = [NSString stringWithFormat:@"MenuItem%dCell", indexPath.row];
		NCTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
		if (!cell)
			cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier];
		return cell;
	}
	else {
		NCTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"FitCell"];
		NCFit* fit = self.fits[indexPath.section - 1][indexPath.row];
		cell.textLabel.text = fit.typeName;
		cell.detailTextLabel.text = fit.fitName;
		cell.imageView.image = [UIImage imageNamed:fit.imageName];
		return cell;
	}
}

#pragma mark - Table view delegate

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell* cell = [tableView cellForRowAtIndexPath:indexPath];
	if (indexPath.row == 3) {
		[self.typePickerViewController presentWithConditions:@[@"invGroups.groupID = invTypes.groupID", @"invGroups.categoryID = 6"]
											inViewController:self
													fromRect:cell.bounds
													  inView:cell
													animated:YES
										   completionHandler:^(EVEDBInvType *type) {
											   NCShipFit* fit = [NCShipFit emptyFit];
											   fit.typeID = type.typeID;
											   [self performSegueWithIdentifier:@"NCFittingShipViewController" sender:fit];
											   [self dismissAnimated];
										   }];
	}
}

#pragma mark - NCTableViewController

- (NSString*) recordID {
	return nil;
}

#pragma mark - Private

- (void) reload {
	NSMutableArray* fits = [NSMutableArray new];
	[[self taskManager] addTaskWithIndentifier:NCTaskManagerIdentifierAuto
										 title:NCTaskManagerDefaultTitle
										 block:^(NCTask *task) {
											 NCStorage* storage = [NCStorage sharedStorage];
											 [storage.managedObjectContext performBlockAndWait:^{
												 NSArray* shipFits = [NCShipFit allFits];
												 task.progress = 0.25;
												 
												 [fits addObjectsFromArray:[shipFits arrayGroupedByKey:@"type.groupID"]];
												 task.progress = 0.5;
												 [fits sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
													 NCShipFit* a = [obj1 objectAtIndex:0];
													 NCShipFit* b = [obj2 objectAtIndex:0];
													 return [a.type.group.groupName compare:b.type.group.groupName];
												 }];
												 
												 task.progress = 0.75;
												 
												 NSMutableArray* posFits = [NSMutableArray arrayWithArray:[NCPOSFit allFits]];
												 if (posFits.count > 0)
													 [fits addObject:posFits];
												 
												 task.progress = 1.0;
											 }];
										 }
							 completionHandler:^(NCTask *task) {
								 self.fits = fits;
								 [self.tableView reloadData];
								 
							 }];
}

- (NCDatabaseTypePickerViewController*) typePickerViewController {
	if (!_typePickerViewController) {
		_typePickerViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"NCDatabaseTypePickerViewController"];
	}
	return _typePickerViewController;
}

@end
