//
//  ImplantsViewController.h
//  EVEUniverse
//
//  Created by Artem Shimanski on 5/12/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FittingSection.h"
#import "FittingItemsViewController.h"

#include "eufe.h"

@class FittingViewController;
@class EVEFittingFit;
@interface ImplantsViewController : UIViewController<FittingSection, UITableViewDelegate, UITableViewDataSource, UIActionSheetDelegate>
@property (nonatomic, assign) IBOutlet FittingViewController *fittingViewController;
@property (nonatomic, retain) IBOutlet UITableView *tableView;
@property (nonatomic, retain) IBOutlet UIView *implantsHeaderView;
@property (nonatomic, retain) IBOutlet UIView *boostersHeaderView;
@property (nonatomic, retain) IBOutlet FittingItemsViewController *fittingItemsViewController;
@property (nonatomic, retain) UIPopoverController *popoverController;

@end
