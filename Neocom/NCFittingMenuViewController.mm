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

@interface NCFittingMenuViewController ()

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

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return section == 0 ? 5 : 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	if (indexPath.section == 0) {
		NSString *CellIdentifier = [NSString stringWithFormat:@"MenuItem%dCell", indexPath.row];
		NCTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
		if (!cell)
			cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier];
		return cell;
	}
	else
		return nil;
}

#pragma mark - Table view delegate

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	if (indexPath.row == 0) {
		UITableViewCell* cell = [tableView cellForRowAtIndexPath:indexPath];
		NCDatabaseTypePickerViewController* controller = [self.storyboard instantiateViewControllerWithIdentifier:@"NCDatabaseTypePickerViewController"];
		[controller presentWithConditions:@[@"invGroups.groupID = invTypes.groupID", @"invGroups.categoryID = 6"]
						 inViewController:self
								 fromRect:cell.bounds
								   inView:cell
								 animated:YES
						completionHandler:^(EVEDBInvType *type) {
							[self dismissAnimated];
						}];
	}
}

#pragma mark - NCTableViewController

- (NSString*) recordID {
	return nil;
}

@end
