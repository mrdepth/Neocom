//
//  AssetsViewController.h
//  EVEUniverse
//
//  Created by Mr. Depth on 2/15/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FilterViewController.h"
#import "EUFilter.h"
#import "EVEAssetListItem+AssetsViewController.h"
#import "ExpandedTableView.h"

@interface AssetsViewController : UIViewController<UITableViewDataSource, ExpandedTableViewDelegate> {
	UITableView *assetsTableView;
	UISegmentedControl *ownerSegmentControl;
	UISearchBar *searchBar;
	FilterViewController *filterViewController;
	UINavigationController *filterNavigationViewController;
	UIPopoverController *filterPopoverController;
@private
	NSMutableArray *filteredValues;
	NSMutableArray *assets;
	NSMutableArray *charAssets;
	NSMutableArray *corpAssets;
	EUFilter *charFilter;
	EUFilter *corpFilter;
}
@property (nonatomic, retain) IBOutlet UITableView *assetsTableView;
@property (nonatomic, retain) IBOutlet UISegmentedControl *ownerSegmentControl;
@property (nonatomic, retain) IBOutlet UISearchBar *searchBar;
@property (nonatomic, retain) IBOutlet FilterViewController *filterViewController;
@property (nonatomic, retain) IBOutlet UINavigationController *filterNavigationViewController;
@property (nonatomic, retain) UIPopoverController *filterPopoverController;

- (IBAction) onChangeOwner:(id) sender;

@end
