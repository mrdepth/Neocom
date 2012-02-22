//
//  FitsViewController.h
//  EVEUniverse
//
//  Created by Mr. Depth on 12/29/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FittingItemsViewController.h"
#import "FitsViewControllerDelegate.h"
#include "eufe.h"

@interface FitsViewController : UIViewController<UITableViewDataSource, UITableViewDelegate, FittingItemsViewControllerDelegate> {
	UITableView *menuTableView;
	FittingItemsViewController *fittingItemsViewController;
	UINavigationController *modalController;
	UIPopoverController *popoverController;
	id<FitsViewControllerDelegate> delegate;
	eufe::Engine* engine;
@private
	NSMutableArray *fits;
	NSInteger lastID;
}
@property (nonatomic, retain) IBOutlet UITableView *menuTableView;
@property (nonatomic, retain) IBOutlet FittingItemsViewController *fittingItemsViewController;
@property (nonatomic, retain) IBOutlet UINavigationController *modalController;
@property (nonatomic, retain) UIPopoverController *popoverController;
@property (nonatomic, assign) id<FitsViewControllerDelegate> delegate;
@property (nonatomic, assign) eufe::Engine* engine;

- (IBAction) didCloseModalViewController:(id) sender;
- (IBAction) onClose:(id) sender;

@end
