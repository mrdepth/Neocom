//
//  NCAccountsViewController.h
//  Neocom
//
//  Created by Admin on 04.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCTableViewController.h"

@interface NCAccountsViewController : NCTableViewController
@property (nonatomic, strong) IBOutlet UIBarButtonItem* logoutItem;
@property (nonatomic, strong) IBOutlet UISegmentedControl* modeSegmentedControl;

- (IBAction)onChangeMode:(id)sender;
@end
