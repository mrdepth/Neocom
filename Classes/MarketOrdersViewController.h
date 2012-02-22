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


@interface MarketOrdersViewController : UIViewController {
	UITableView *marketOrdersTableView;
	UISegmentedControl *ownerSegmentControl;
	UISearchBar *searchBar;
	FilterViewController *filterViewController;
	UINavigationController *filterNavigationViewController;
	UIPopoverController *filterPopoverController;
@private
	NSMutableArray *filteredValues;
	NSMutableArray *orders;
	NSMutableArray *charOrders;
	NSMutableArray *corpOrders;
	NSMutableDictionary *conquerableStations;
	EUFilter *charFilter;
	EUFilter *corpFilter;
}
@property (nonatomic, retain) IBOutlet UITableView *marketOrdersTableView;
@property (nonatomic, retain) IBOutlet UISegmentedControl *ownerSegmentControl;
@property (nonatomic, retain) IBOutlet UISearchBar *searchBar;
@property (nonatomic, retain) IBOutlet FilterViewController *filterViewController;
@property (nonatomic, retain) IBOutlet UINavigationController *filterNavigationViewController;
@property (nonatomic, retain) UIPopoverController *filterPopoverController;

- (IBAction) onChangeOwner:(id) sender;

@end
