//
//  NCAssetsAccountsViewController.h
//  Neocom
//
//  Created by Артем Шиманский on 02.05.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCTableViewController.h"

@class NCAssetsAccountsViewController;
@protocol NCAssetsAccountsViewControllerDelegate <NSObject>

- (void) assetsAccountsViewController:(NCAssetsAccountsViewController*) controller didSelectAccounts:(NSArray*) accounts;

@end

@interface NCAssetsAccountsViewController : NCTableViewController
@property (nonatomic, strong) NSArray* selectedAccounts;
@property (nonatomic, weak) id<NCAssetsAccountsViewControllerDelegate> delegate;
@end
