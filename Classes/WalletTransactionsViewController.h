//
//  WalletTransactionsViewController.h
//  EVEUniverse
//
//  Created by Artem Shimanski on 2/26/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SBTableView.h"
#import "FilterViewController.h"
#import "EUFilter.h"

@interface WalletTransactionsViewController : UIViewController<UITableViewDelegate, UITableViewDataSource>
@property (nonatomic, weak) IBOutlet SBTableView *walletTransactionsTableView;
@property (nonatomic, weak) IBOutlet UISegmentedControl *ownerSegmentControl;
@property (nonatomic, weak) IBOutlet UISegmentedControl *accountSegmentControl;
@property (nonatomic, weak) IBOutlet UIView *accountsView;
@property (nonatomic, weak) IBOutlet UIToolbar *ownerToolbar;
@property (nonatomic, weak) IBOutlet UIToolbar *accountToolbar;
@property (nonatomic, weak) IBOutlet UISearchBar *searchBar;
@property (nonatomic, weak) IBOutlet FilterViewController *filterViewController;
@property (nonatomic, strong) IBOutlet UINavigationController *filterNavigationViewController;
@property (nonatomic, strong) UIPopoverController *filterPopoverController;

- (IBAction) onChangeOwner:(id) sender;
- (IBAction) onChangeAccount:(id) sender;

@end
