//
//  EVEAccountsViewController.h
//  EVEUniverse
//
//  Created by Artem Shimanski on 9/2/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class EVEAccountsDataSource;
@interface EVEAccountsViewController : UIViewController<UICollectionViewDelegate>
@property (nonatomic, strong) IBOutlet EVEAccountsDataSource* dataSource;
@property (nonatomic, weak) IBOutlet UICollectionView* collectionView;

- (IBAction) onAddAccount: (id) sender;
- (IBAction) onLogoff: (id) sender;
- (IBAction) onClose:(id)sender;
@end

