//
//  FittingServiceMenuViewController.h
//  EVEUniverse
//
//  Created by Artem Shimanski on 5/13/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FittingItemsViewController.h"


@interface FittingServiceMenuViewController : UITableViewController<FittingItemsViewControllerDelegate, UIAlertViewDelegate, MFMailComposeViewControllerDelegate>
@property (nonatomic, weak) IBOutlet FittingItemsViewController *fittingItemsViewController;
@property (nonatomic, strong) IBOutlet UINavigationController *modalController;
@property (nonatomic, strong) UIPopoverController *popoverController;

- (IBAction) didCloseModalViewController:(id) sender;

@end
