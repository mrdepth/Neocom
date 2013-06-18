//
//  ModulesViewController.h
//  EVEUniverse
//
//  Created by Artem Shimanski on 5/10/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FittingItemsViewControllerDelegate.h"
#import "ProgressLabel.h"
#import "FittingSection.h"
#import "TargetsViewController.h"

#include "eufe.h"

@class FittingViewController;
@interface ModulesViewController : UIViewController<FittingSection, UITableViewDelegate, UITableViewDataSource, UIActionSheetDelegate>
@property (nonatomic, assign) IBOutlet FittingViewController *fittingViewController;
@property (nonatomic, retain) IBOutlet UITableView *tableView;
@property (nonatomic, retain) IBOutlet ProgressLabel *powerGridLabel;
@property (nonatomic, retain) IBOutlet ProgressLabel *cpuLabel;
@property (nonatomic, retain) IBOutlet ProgressLabel *calibrationLabel;
@property (nonatomic, retain) IBOutlet UILabel *turretsLabel;
@property (nonatomic, retain) IBOutlet UILabel *launchersLabel;
@property (nonatomic, retain) IBOutlet UIView *highSlotsHeaderView;
@property (nonatomic, retain) IBOutlet UIView *medSlotsHeaderView;
@property (nonatomic, retain) IBOutlet UIView *lowSlotsHeaderView;
@property (nonatomic, retain) IBOutlet UIView *rigsSlotsHeaderView;
@property (nonatomic, retain) IBOutlet UIView *subsystemsSlotsHeaderView;
@property (nonatomic, retain) IBOutlet FittingItemsViewController *fittingItemsViewController;
@property (nonatomic, retain) IBOutlet TargetsViewController* targetsViewController;
@property (nonatomic, retain) UIPopoverController *popoverController;

@end