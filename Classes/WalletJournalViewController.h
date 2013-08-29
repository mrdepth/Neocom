//
//  WalletJournalViewController.h
//  EVEUniverse
//
//  Created by Mr. Depth on 2/27/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FilterViewController.h"
#import "EUFilter.h"

@interface WalletJournalViewController : UITableViewController {
}
@property (nonatomic, strong) IBOutlet UISegmentedControl *ownerSegmentControl;
@property (nonatomic, weak) IBOutlet UISegmentedControl *accountSegmentControl;
@property (nonatomic, weak) IBOutlet UIView *accountsView;
@property (nonatomic, weak) IBOutlet UIToolbar *ownerToolbar;
@property (nonatomic, weak) IBOutlet UIToolbar *accountToolbar;
@property (nonatomic, weak) IBOutlet UISearchBar *searchBar;
@property (nonatomic, weak) IBOutlet FilterViewController *filterViewController;
@property (nonatomic, strong) IBOutlet UINavigationController *filterNavigationViewController;

- (IBAction) onChangeOwner:(id) sender;
- (IBAction) onChangeAccount:(id) sender;

@end
