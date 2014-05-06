//
//  NCFittingShipWorkspaceViewController.m
//  Neocom
//
//  Created by Артем Шиманский on 29.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCFittingShipWorkspaceViewController.h"
#import "NCTableViewHeaderView.h"
#import "UIColor+Neocom.h"

@interface NCFittingShipWorkspaceViewController ()

@end

@implementation NCFittingShipWorkspaceViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	self.refreshControl = nil;
	
	[self.tableView registerNib:[UINib nibWithNibName:@"NCFittingSectionGenericHeaderView" bundle:nil] forHeaderFooterViewReuseIdentifier:@"NCFittingSectionGenericHeaderView"];
	[self.tableView registerNib:[UINib nibWithNibName:@"NCFittingSectionHiSlotHeaderView" bundle:nil] forHeaderFooterViewReuseIdentifier:@"NCFittingSectionHiSlotHeaderView"];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - NCTableViewController

- (NSString*) recordID {
	return nil;
}

@end
