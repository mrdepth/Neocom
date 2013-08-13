//
//  StructuresViewController.h
//  EVEUniverse
//
//  Created by Mr. Depth on 3/15/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FittingItemsViewControllerDelegate.h"
#import "ProgressLabel.h"
#import "FittingSection.h"
#import "AmountViewController.h"

#include "eufe.h"

@class POSFittingViewController;
@interface StructuresViewController : UIViewController<FittingSection, UITableViewDelegate, UITableViewDataSource, UIActionSheetDelegate>

@property (nonatomic, weak) IBOutlet POSFittingViewController *posFittingViewController;
@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic, weak) IBOutlet ProgressLabel *powerGridLabel;
@property (nonatomic, weak) IBOutlet ProgressLabel *cpuLabel;
@property (nonatomic, weak) IBOutlet FittingItemsViewController *fittingItemsViewController;
@property (nonatomic, strong) UIPopoverController *popoverController;

@end