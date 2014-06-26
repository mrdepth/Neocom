//
//  NCKillMailsViewController.h
//  Neocom
//
//  Created by Артем Шиманский on 21.02.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCTableViewController.h"

@interface NCKillMailsViewController : NCTableViewController
@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentedControl;
- (IBAction)onChangeMode:(id)sender;

@end
