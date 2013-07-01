//
//  AccountsSelectionViewController.h
//  EVEUniverse
//
//  Created by Artem Shimanski on 20.11.12.
//
//

#import <UIKit/UIKit.h>

@class AccountsSelectionViewController;
@protocol AccountsSelectionViewControllerDelegate
- (void) accountsSelectionViewController:(AccountsSelectionViewController*) controller didSelectAccounts:(NSArray*) accounts;
@end

@interface AccountsSelectionViewController : UITableViewController
@property (nonatomic, strong) NSArray* selectedAccounts;
@property (nonatomic, weak) id<AccountsSelectionViewControllerDelegate> delegate;

@end
