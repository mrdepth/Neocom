//
//  FittingServiceMenuViewController.h
//  EVEUniverse
//
//  Created by Artem Shimanski on 5/13/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NCItemsViewController.h"


@interface FittingServiceMenuViewController : UITableViewController<MFMailComposeViewControllerDelegate>
@property (nonatomic, strong) IBOutlet NCItemsViewController *itemsViewController;

- (IBAction) didCloseModalViewController:(id) sender;

@end
