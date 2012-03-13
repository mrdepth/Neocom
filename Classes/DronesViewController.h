//
//  DronesViewController.h
//  EVEUniverse
//
//  Created by Artem Shimanski on 5/11/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ProgressLabel.h"
#import "DronesAmountViewController.h"
#import "FittingSection.h"
#import "TargetsViewController.h"
#import "FittingItemsViewController.h"

@class FittingViewController;
@class EVEFittingFit;
@interface DronesViewController : UIViewController<FittingSection, UITableViewDelegate, UITableViewDataSource, UIActionSheetDelegate, DronesAmountViewControllerDelegate> {
	FittingViewController *fittingViewController;
	UITableView *tableView;
	ProgressLabel *droneBayLabel;
	ProgressLabel *droneBandwidthLabel;
	UILabel *dronesCountLabel;
	FittingItemsViewController *fittingItemsViewController;
	TargetsViewController* targetsViewController;
	UIPopoverController *popoverController;
@private
	NSMutableArray *rows;
	NSIndexPath *modifiedIndexPath;
}
@property (nonatomic, assign) IBOutlet FittingViewController *fittingViewController;
@property (nonatomic, retain) IBOutlet UITableView *tableView;
@property (nonatomic, retain) IBOutlet ProgressLabel *droneBayLabel;
@property (nonatomic, retain) IBOutlet ProgressLabel *droneBandwidthLabel;
@property (nonatomic, retain) IBOutlet UILabel *dronesCountLabel;
@property (nonatomic, retain) IBOutlet FittingItemsViewController *fittingItemsViewController;
@property (nonatomic, retain) IBOutlet TargetsViewController* targetsViewController;
@property (nonatomic, retain) UIPopoverController *popoverController;

@end
