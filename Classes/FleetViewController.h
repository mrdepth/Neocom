//
//  FleetViewController.h
//  EVEUniverse
//
//  Created by Mr. Depth on 12/20/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FittingSection.h"

#include "eufe.h"

@class FittingViewController;
@class EVEFittingFit;
@interface FleetViewController : UIViewController<FittingSection, UITableViewDelegate, UITableViewDataSource, UIActionSheetDelegate>
@property (nonatomic, assign) IBOutlet FittingViewController *fittingViewController;
@property (nonatomic, retain) IBOutlet UITableView *tableView;

@end
