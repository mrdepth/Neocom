//
//  FittingServiceMenuViewController.h
//  EVEUniverse
//
//  Created by Artem Shimanski on 5/13/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FittingItemsViewController.h"


@interface FittingServiceMenuViewController : UIViewController<UITableViewDataSource, UITableViewDelegate, FittingItemsViewControllerDelegate, UIAlertViewDelegate, MFMailComposeViewControllerDelegate>
@property (nonatomic, retain) IBOutlet UITableView *menuTableView;
@property (nonatomic, retain) IBOutlet FittingItemsViewController *fittingItemsViewController;
@property (nonatomic, retain) IBOutlet UINavigationController *modalController;
@property (nonatomic, retain) UIPopoverController *popoverController;

- (IBAction) didCloseModalViewController:(id) sender;

@end
