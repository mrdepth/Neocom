//
//  DronesViewController.h
//  EVEUniverse
//
//  Created by Artem Shimanski on 5/11/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ProgressLabel.h"
#import "DronesAmountViewController.h"
#import "FittingSection.h"
#import "TargetsViewController.h"
#import "FittingItemsViewController.h"

@class FittingViewController;
@class EVEFittingFit;
@interface DronesViewController : UIViewController<FittingSection, UITableViewDelegate, UITableViewDataSource, UIActionSheetDelegate, DronesAmountViewControllerDelegate>
@property (nonatomic, weak) IBOutlet FittingViewController *fittingViewController;
@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic, weak) IBOutlet ProgressLabel *droneBayLabel;
@property (nonatomic, weak) IBOutlet ProgressLabel *droneBandwidthLabel;
@property (nonatomic, weak) IBOutlet UILabel *dronesCountLabel;
@property (nonatomic, weak) IBOutlet FittingItemsViewController *fittingItemsViewController;
@property (nonatomic, weak) IBOutlet TargetsViewController* targetsViewController;
@property (nonatomic, strong) UIPopoverController *popoverController;

@end
