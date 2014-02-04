//
//  NCFittingShipWorkspaceViewController.m
//  Neocom
//
//  Created by Артем Шиманский on 29.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCFittingShipWorkspaceViewController.h"

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
	[self.tableView registerNib:[UINib nibWithNibName:@"NCFittingSectionGenericHedaerView" bundle:nil] forHeaderFooterViewReuseIdentifier:@"NCFittingSectionGenericHedaerView"];
	[self.tableView registerNib:[UINib nibWithNibName:@"NCFittingSectionHiSlotHedaerView" bundle:nil] forHeaderFooterViewReuseIdentifier:@"NCFittingSectionHiSlotHedaerView"];

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

@end
