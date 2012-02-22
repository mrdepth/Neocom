//
//  POSesViewController.h
//  EVEUniverse
//
//  Created by Artem Shimanski on 3/1/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface POSesViewController : UIViewController<UITableViewDelegate, UITableViewDataSource> {
	UITableView *posesTableView;
	UISearchBar *searchBar;
@private
	NSMutableArray *poses;
	NSMutableArray *sections;
	NSMutableDictionary *sovereigntySolarSystems;
	NSMutableArray *filteredValues;
}
@property (nonatomic, retain) IBOutlet UITableView *posesTableView;
@property (nonatomic, retain) IBOutlet UISearchBar *searchBar;
@end
