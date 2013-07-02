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
@interface BCSearchViewController : UITableViewController<FittingItemsViewControllerDelegate>
@property (nonatomic, weak) IBOutlet FittingItemsViewController *fittingItemsViewController;
@property (nonatomic, strong) IBOutlet UINavigationController *modalController;
@property (nonatomic, strong) IBOutlet UIBarButtonItem *searchButton;
@property (nonatomic, strong) UIPopoverController *popoverController;

- (IBAction) didCloseModalViewController:(id) sender;
- (IBAction) onSearch:(id) sender;
@end
