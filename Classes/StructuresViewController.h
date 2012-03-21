//
//  StructuresViewController.h
//  EVEUniverse
//
//  Created by Mr. Depth on 3/15/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FittingItemsViewControllerDelegate.h"
#import "ProgressLabel.h"
#import "FittingSection.h"
#import "DronesAmountViewController.h"

#include "eufe.h"

@class POSFittingViewController;
@interface StructuresViewController : UIViewController<FittingSection, UITableViewDelegate, UITableViewDataSource, UIActionSheetDelegate, DronesAmountViewControllerDelegate> {
	POSFittingViewController *posFittingViewController;
	UITableView *tableView;
	ProgressLabel *powerGridLabel;
	ProgressLabel *cpuLabel;
	FittingItemsViewController *fittingItemsViewController;
	UIPopoverController *popoverController;
@private
	NSMutableArray *structures;
	NSIndexPath *modifiedIndexPath;
}

@property (nonatomic, assign) IBOutlet POSFittingViewController *posFittingViewController;
@property (nonatomic, retain) IBOutlet UITableView *tableView;
@property (nonatomic, retain) IBOutlet ProgressLabel *powerGridLabel;
@property (nonatomic, retain) IBOutlet ProgressLabel *cpuLabel;
@property (nonatomic, retain) IBOutlet FittingItemsViewController *fittingItemsViewController;
@property (nonatomic, retain) UIPopoverController *popoverController;

@end