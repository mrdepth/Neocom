//
//  BCSearchViewController.h
//  EVEUniverse
//
//  Created by Artem Shimanski on 5/14/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FittingItemsViewController.h"

@class EVEDBInvType;
@interface BCSearchViewController : UIViewController<UITableViewDataSource, UITableViewDelegate, FittingItemsViewControllerDelegate>
@property (nonatomic, retain) IBOutlet UITableView *menuTableView;
@property (nonatomic, retain) IBOutlet FittingItemsViewController *fittingItemsViewController;
@property (nonatomic, retain) IBOutlet UINavigationController *modalController;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *searchButton;
@property (nonatomic, retain) UIPopoverController *popoverController;

- (IBAction) didCloseModalViewController:(id) sender;
- (IBAction) onSearch:(id) sender;
@end
