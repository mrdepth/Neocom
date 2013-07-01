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
@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic, weak) IBOutlet ProgressLabel *powerGridLabel;
@property (nonatomic, weak) IBOutlet ProgressLabel *cpuLabel;
@property (nonatomic, weak) IBOutlet ProgressLabel *calibrationLabel;
@property (nonatomic, weak) IBOutlet UILabel *turretsLabel;
@property (nonatomic, weak) IBOutlet UILabel *launchersLabel;
@property (nonatomic, strong) IBOutlet UIView *highSlotsHeaderView;
@property (nonatomic, strong) IBOutlet UIView *medSlotsHeaderView;
@property (nonatomic, strong) IBOutlet UIView *lowSlotsHeaderView;
@property (nonatomic, strong) IBOutlet UIView *rigsSlotsHeaderView;
@property (nonatomic, strong) IBOutlet UIView *subsystemsSlotsHeaderView;
@property (nonatomic, weak) IBOutlet FittingItemsViewController *fittingItemsViewController;
@property (nonatomic, weak) IBOutlet TargetsViewController* targetsViewController;
@property (nonatomic, strong) UIPopoverController *popoverController;

@end