//
//  ItemsDBViewController.h
//  EVEUniverse
//
//  Created by Artem Shimanski on 8/30/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EVEDBAPI.h"

@interface ItemsDBViewController : UIViewController<UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate> {
	UITableView *itemsTable;
	UISearchBar *searchBar;
	UISegmentedControl *publishedFilterSegment;
	EVEDBInvCategory *category;
	EVEDBInvGroup *group;
	NSMutableArray *rows;
	NSArray *filteredValues;
	BOOL modalMode;
}
@property (nonatomic, retain) IBOutlet UITableView *itemsTable;
@property (nonatomic, retain) IBOutlet UISearchBar *searchBar;
@property (nonatomic, retain) IBOutlet UISegmentedControl *publishedFilterSegment;
@property (nonatomic, retain) EVEDBInvCategory *category;
@property (nonatomic, retain) EVEDBInvGroup *group;
@property (nonatomic, retain) NSMutableArray *rows;
@property (nonatomic, retain) NSArray *filteredValues;
@property (nonatomic, getter=isModalMode) BOOL modalMode;

- (IBAction) onChangePublishedFilterSegment: (id) sender;
@end
