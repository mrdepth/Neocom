//
//  BCSearchViewController.h
//  EVEUniverse
//
//  Created by Artem Shimanski on 5/14/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NCItemsViewController.h"

@interface BCSearchViewController : UITableViewController
@property (strong, nonatomic) IBOutlet NCItemsViewController *itemsViewController;

- (IBAction) onSearch:(id) sender;
@end
