//
//  TargetsViewController.h
//  EVEUniverse
//
//  Created by mr_depth on 02.01.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TargetsViewControllerDelegate.h"
#include "eufe.h"

@class FittingViewController;
@class ItemInfo;
@interface TargetsViewController : UIViewController<UITableViewDelegate, UITableViewDataSource, UIPopoverControllerDelegate>
@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic, weak) IBOutlet FittingViewController* fittingViewController;
@property (nonatomic, weak) IBOutlet id<TargetsViewControllerDelegate> delegate;
@property (nonatomic, assign) eufe::Ship* currentTarget;
@property (nonatomic, strong) ItemInfo* modifiedItem;

@end
