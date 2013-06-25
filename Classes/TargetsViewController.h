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
@property (nonatomic, retain) IBOutlet UITableView *tableView;
@property (nonatomic, assign) IBOutlet FittingViewController* fittingViewController;
@property (nonatomic, assign) IBOutlet id<TargetsViewControllerDelegate> delegate;
@property (nonatomic, assign) eufe::Ship* currentTarget;
@property (nonatomic, retain) ItemInfo* modifiedItem;

@end
