//
//  NCFittingPOSWorkspaceViewController.m
//  Neocom
//
//  Created by Артем Шиманский on 11.02.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCFittingPOSWorkspaceViewController.h"
#import "NCTableViewHeaderView.h"
#import "UIColor+Neocom.h"
@interface NCFittingPOSWorkspaceViewController ()

@end

@implementation NCFittingPOSWorkspaceViewController

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
