//
//  MarketGroupsViewController.h
//  EVEUniverse
//
//  Created by Artem Shimanski on 9/1/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EVEDBAPI.h"
#import "CollapsableTableView.h"

@interface MarketGroupsViewController : UITableViewController<UISearchBarDelegate>
@property (nonatomic, strong) IBOutlet UISearchBar *searchBar;
@property (nonatomic, weak) EVEDBInvMarketGroup *parentGroup;
@property (nonatomic, strong) NSMutableArray *subGroups;
@property (nonatomic, strong) NSMutableArray *groupItems;
@property (nonatomic, strong) NSMutableArray *filteredValues;

@end
