//
//  TargetsViewController.h
//  EVEUniverse
//
//  Created by mr_depth on 02.01.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#include "eufe.h"

@class FittingViewController;
@class ItemInfo;
@interface TargetsViewController : UITableViewController
@property (nonatomic, weak) IBOutlet FittingViewController* fittingViewController;
@property (nonatomic, assign) eufe::Ship* currentTarget;
@property (nonatomic, copy) void (^completionHandler)(eufe::Ship* target);

@end
