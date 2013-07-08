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
@interface AssetContentsViewController : UITableViewController<UITableViewDataSource, CollapsableTableViewDelegate>
@property (nonatomic, strong) IBOutlet UISearchBar *searchBar;
@property (nonatomic, strong) IBOutlet FilterViewController *filterViewController;
@property (nonatomic, strong) IBOutlet UINavigationController *filterNavigationViewController;
@property (nonatomic, strong) UIPopoverController *filterPopoverController;
@property (nonatomic, strong) EVEAssetListItem *asset;
@property (nonatomic, assign, getter = isCorporate) BOOL corporate;

- (IBAction)onOpenFit:(id)sender;

@end
