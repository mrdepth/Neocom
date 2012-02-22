//
//  FleetViewController.h
//  EVEUniverse
//
//  Created by Mr. Depth on 12/20/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FittingItemsViewControllerDelegate.h"
#import "FittingSection.h"
#import "CharactersViewController.h"
#import "FitsViewController.h"

#include "eufe.h"

@class FittingViewController;
@class EVEFittingFit;
@interface FleetViewController : UIViewController<FittingSection, UITableViewDelegate, UITableViewDataSource, FittingItemsViewControllerDelegate, UIActionSheetDelegate, CharactersViewControllerDelegate, FitsViewControllerDelegate> {
	FittingViewController *fittingViewController;
	UITableView *tableView;
	FittingItemsViewController *fittingItemsViewController;
	UIPopoverController *popoverController;
	
@private
	NSMutableArray* pilots;
	NSIndexPath *modifiedIndexPath;
}
@property (nonatomic, assign) IBOutlet FittingViewController *fittingViewController;
@property (nonatomic, retain) IBOutlet UITableView *tableView;
@property (nonatomic, retain) IBOutlet FittingItemsViewController *fittingItemsViewController;
@property (nonatomic, retain) UIPopoverController *popoverController;

@end
