//
//  NCFittingAPISearchResultsViewController.h
//  Neocom
//
//  Created by Артем Шиманский on 13.02.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCTableViewController.h"

@interface NCFittingAPISearchResultsViewController : NCTableViewController
@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentedControl;
@property (nonatomic, strong) NSDictionary* criteria;
- (IBAction)onChangeOrder:(id)sender;
@end
