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
@property (nonatomic, weak) IBOutlet FittingViewController *fittingViewController;
@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic, strong) IBOutlet UIView *implantsHeaderView;
@property (nonatomic, strong) IBOutlet UIView *boostersHeaderView;
@property (nonatomic, weak) IBOutlet FittingItemsViewController *fittingItemsViewController;
@property (nonatomic, strong) UIPopoverController *popoverController;

@end
