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
@interface TargetsViewController : UIViewController<UITableViewDelegate, UITableViewDataSource, UIPopoverControllerDelegate> {
	UITableView *tableView;
	FittingViewController* fittingViewController;
	eufe::Ship* currentTarget;
	id<TargetsViewControllerDelegate> delegate;
	ItemInfo* modifiedItem;
@private
	NSArray* targets;
}
@property (nonatomic, retain) IBOutlet UITableView *tableView;
@property (nonatomic, assign) IBOutlet FittingViewController* fittingViewController;
@property (nonatomic, assign) eufe::Ship* currentTarget;
@property (nonatomic, assign) id<TargetsViewControllerDelegate> delegate;
@property (nonatomic, retain) ItemInfo* modifiedItem;

@end
