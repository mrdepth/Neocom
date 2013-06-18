//
//  EVEAccountsViewController.h
//  EVEUniverse
//
//  Created by Artem Shimanski on 9/2/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface EVEAccountsViewController : UIViewController<UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, retain) IBOutlet UITableView *accountsTableView;
@property (nonatomic, retain) IBOutlet UIButton *logoffButton;

- (IBAction) onAddAccount: (id) sender;
- (IBAction) onLogoff: (id) sender;
@end
