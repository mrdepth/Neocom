//
//  NCFittingShipStatsViewController.m
//  Neocom
//
//  Created by Артем Шиманский on 01.04.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCFittingShipStatsViewController.h"
#import "NCTableViewHeaderView.h"

@interface NCFittingShipStatsViewController ()

@end

@implementation NCFittingShipStatsViewController

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
	[self.tableView registerClass:[NCTableViewHeaderView class] forHeaderFooterViewReuseIdentifier:@"NCTableViewHeaderView"];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
