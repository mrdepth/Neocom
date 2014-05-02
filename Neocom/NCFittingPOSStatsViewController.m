//
//  NCFittingPOSStatsViewController.m
//  Neocom
//
//  Created by Артем Шиманский on 02.04.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCFittingPOSStatsViewController.h"
#import "NCTableViewHeaderView.h"
#import "UIColor+Neocom.h"
@interface NCFittingPOSStatsViewController ()

@end

@implementation NCFittingPOSStatsViewController

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
	self.tableView.backgroundColor = [UIColor appearanceTableViewBackgroundColor];
	[self.tableView registerClass:[NCTableViewHeaderView class] forHeaderFooterViewReuseIdentifier:@"NCTableViewHeaderView"];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
