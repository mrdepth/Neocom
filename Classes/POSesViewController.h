//
//  POSesViewController.h
//  EVEUniverse
//
//  Created by Artem Shimanski on 3/1/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface POSesViewController : UIViewController<UITableViewDelegate, UITableViewDataSource>
@property (nonatomic, weak) IBOutlet UITableView *posesTableView;
@property (nonatomic, weak) IBOutlet UISearchBar *searchBar;
@end
