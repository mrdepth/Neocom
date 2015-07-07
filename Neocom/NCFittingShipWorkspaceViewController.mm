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
#import "NCFittingShipViewController.h"

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

- (void)viewDidLoad {
    [super viewDidLoad];
	self.refreshControl = nil;
	[self.tableView registerNib:[UINib nibWithNibName:@"NCFittingSectionGenericHeaderView" bundle:nil] forHeaderFooterViewReuseIdentifier:@"NCFittingSectionGenericHeaderView"];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) reload {
	
}

- (NCFittingShipViewController*) controller {
	return (NCFittingShipViewController*) self.parentViewController;
}

- (NCTaskManager*) taskManager {
	return [self.controller taskManager];
}

#pragma mark - NCTableViewController

- (NSString*) recordID {
	return nil;
}

@end
