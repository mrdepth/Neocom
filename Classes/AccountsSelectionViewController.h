//
//  AccountsSelectionViewController.h
//  EVEUniverse
//
//  Created by Artem Shimanski on 20.11.12.
//
//

#import <UIKit/UIKit.h>
#import "ASCollectionView.h"
#import "ASCollectionViewFlowLayout.h"
#import "EVEAccountsDataSource.h"

@class AccountsSelectionViewController;
@protocol AccountsSelectionViewControllerDelegate
- (void) accountsSelectionViewController:(AccountsSelectionViewController*) controller didSelectAccounts:(NSArray*) accounts;
@end

@interface AccountsSelectionViewController : UIViewController<ASCollectionViewDelegateFlowLayout>
@property (nonatomic, strong) IBOutlet EVEAccountsDataSource* dataSource;
@property (nonatomic, weak) IBOutlet ASCollectionView* collectionView;
@property (nonatomic, strong) NSArray* selectedAccounts;
@property (nonatomic, weak) id<AccountsSelectionViewControllerDelegate> delegate;

@end
