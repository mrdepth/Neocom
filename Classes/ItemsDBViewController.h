//
//  ItemsDBViewController.h
//  EVEUniverse
//
//  Created by Artem Shimanski on 8/30/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EVEDBAPI.h"

typedef enum {
	ItemsDBViewControllerModePublished,
	ItemsDBViewControllerModeNotPublished,
	ItemsDBViewControllerModeAll
} ItemsDBViewControllerMode;

@interface ItemsDBViewController : UITableViewController<UISearchBarDelegate>
@property (nonatomic, strong) IBOutlet UISearchBar *searchBar;
@property (nonatomic, weak) IBOutlet UISegmentedControl *publishedFilterSegment;
@property (nonatomic, strong) EVEDBInvCategory *category;
@property (nonatomic, strong) EVEDBInvGroup *group;
@property (nonatomic, strong) NSMutableArray *rows;
@property (nonatomic, strong) NSArray *filteredValues;
@property (nonatomic, getter=isModalMode) BOOL modalMode;
@property (nonatomic, readonly) ItemsDBViewControllerMode mode;

- (IBAction) onChangePublishedFilterSegment: (id) sender;
@end
