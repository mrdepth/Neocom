//
//  WalletJournalViewController.h
//  EVEUniverse
//
//  Created by Mr. Depth on 2/27/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SBTableView.h"
#import "FilterViewController.h"
#import "EUFilter.h"

@interface WalletJournalViewController : UIViewController<UITableViewDelegate, UITableViewDataSource> {
}
@property (nonatomic, retain) IBOutlet SBTableView *walletJournalTableView;
@property (nonatomic, retain) IBOutlet UISegmentedControl *ownerSegmentControl;
@property (nonatomic, retain) IBOutlet UISegmentedControl *accountSegmentControl;
@property (nonatomic, retain) IBOutlet UIView *accountsView;
@property (nonatomic, retain) IBOutlet UIToolbar *ownerToolbar;
@property (nonatomic, retain) IBOutlet UIToolbar *accountToolbar;
@property (nonatomic, retain) IBOutlet UISearchBar *searchBar;
@property (nonatomic, retain) IBOutlet FilterViewController *filterViewController;
@property (nonatomic, retain) IBOutlet UINavigationController *filterNavigationViewController;
@property (nonatomic, retain) UIPopoverController *filterPopoverController;

- (IBAction) onChangeOwner:(id) sender;
- (IBAction) onChangeAccount:(id) sender;

@end
