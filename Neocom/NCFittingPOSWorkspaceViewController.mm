//
//  NCFittingPOSWorkspaceViewController.m
//  Neocom
//
//  Created by Артем Шиманский on 11.02.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCFittingPOSWorkspaceViewController.h"
#import "NCFittingPOSViewController.h"
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

- (NCFittingPOSViewController*) controller {
	return (NCFittingPOSViewController*) self.parentViewController;
}

- (NCTaskManager*) taskManager {
	return [self.controller taskManager];
}

#pragma mark - NCTableViewController

- (NSString*) recordID {
	return nil;
}

@end
