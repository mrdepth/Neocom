//
//  AssetContentsViewController.h
//  EVEUniverse
//
//  Created by Mr. Depth on 2/16/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FilterViewController.h"
#import "EUFilter.h"
#import "CollapsableTableView.h"

@class EVEAssetListItem;
@interface AssetContentsViewController : UIViewController<UITableViewDataSource, CollapsableTableViewDelegate> {
	UITableView *assetsTableView;
	UISearchBar *searchBar;
	FilterViewController *filterViewController;
	UINavigationController *filterNavigationViewController;
	UIPopoverController *filterPopoverController;
	EVEAssetListItem *asset;
	BOOL corporate;
@private
	NSMutableArray *filteredValues;
	NSArray *assets;
	NSArray *sections;
	EUFilter *filter;
}
@property (nonatomic, retain) IBOutlet UITableView *assetsTableView;
@property (nonatomic, retain) IBOutlet UISearchBar *searchBar;
@property (nonatomic, retain) IBOutlet FilterViewController *filterViewController;
@property (nonatomic, retain) IBOutlet UINavigationController *filterNavigationViewController;
@property (nonatomic, retain) UIPopoverController *filterPopoverController;
@property (nonatomic, retain) EVEAssetListItem *asset;
@property (nonatomic, assign, getter = isCorporate) BOOL corporate;

- (IBAction)onOpenFit:(id)sender;

@end
