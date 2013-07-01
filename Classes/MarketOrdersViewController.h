//
//  MarketOrdersViewController.h
//  EVEUniverse
//
//  Created by Artem Shimanski on 2/27/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FilterViewController.h"
#import "EUFilter.h"


@interface MarketOrdersViewController : UIViewController

@property (nonatomic, weak) IBOutlet UITableView *marketOrdersTableView;
@property (nonatomic, weak) IBOutlet UISegmentedControl *ownerSegmentControl;
@property (nonatomic, weak) IBOutlet UISearchBar *searchBar;
@property (nonatomic, weak) IBOutlet FilterViewController *filterViewController;
@property (nonatomic, strong) IBOutlet UINavigationController *filterNavigationViewController;
@property (nonatomic, strong) UIPopoverController *filterPopoverController;

- (IBAction) onChangeOwner:(id) sender;

@end
