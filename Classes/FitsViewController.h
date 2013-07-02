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

@interface FitsViewController : UITableViewController<FittingItemsViewControllerDelegate>
@property (nonatomic, weak) IBOutlet FittingItemsViewController *fittingItemsViewController;
@property (nonatomic, strong) IBOutlet UINavigationController *modalController;
@property (nonatomic, strong) UIPopoverController *popoverController;
@property (nonatomic, weak) id<FitsViewControllerDelegate> delegate;
@property (nonatomic, assign) eufe::Engine* engine;

- (IBAction) didCloseModalViewController:(id) sender;
- (IBAction) onClose:(id) sender;

@end
