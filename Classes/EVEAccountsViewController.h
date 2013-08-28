//
//  EVEAccountsViewController.h
//  EVEUniverse
//
//  Created by Artem Shimanski on 9/2/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ASCollectionView.h"
#import "ASCollectionViewPanLayout.h"

@class EVEAccountsDataSource;
@interface EVEAccountsViewController : UIViewController<ASCollectionViewDelegatePanLayout>
@property (nonatomic, strong) IBOutlet EVEAccountsDataSource* dataSource;
@property (nonatomic, weak) IBOutlet ASCollectionView* collectionView;

- (IBAction) onAddAccount: (id) sender;
- (IBAction) onLogoff: (id) sender;
- (IBAction) onClose:(id)sender;
@end

