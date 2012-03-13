//
//  FittingItemsViewController.h
//  EVEUniverse
//
//  Created by Artem Shimanski on 5/8/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FittingItemsViewControllerDelegate.h"

@class EVEDBInvGroup;
@class ItemInfo;
@interface FittingItemsViewController : UIViewController<UITableViewDelegate, UITableViewDataSource, FittingItemsViewControllerDelegate, UIPopoverControllerDelegate> {
	UITableView *tableView;
	NSString *groupsRequest;
	NSString *typesRequest;
	EVEDBInvGroup *group;
	id<FittingItemsViewControllerDelegate> delegate;
	UIViewController *mainViewController;
	ItemInfo* modifiedItem;
@protected
	NSMutableArray *sections;
	NSMutableArray *filteredSections;
	BOOL needsReload;
}
@property (nonatomic, retain) IBOutlet UITableView *tableView;
@property (nonatomic, assign) IBOutlet UIViewController *mainViewController;
@property (nonatomic, retain) NSString *groupsRequest;
@property (nonatomic, retain) NSString *typesRequest;
@property (nonatomic, retain) EVEDBInvGroup *group;
@property (nonatomic, assign) IBOutlet id<FittingItemsViewControllerDelegate> delegate;
@property (nonatomic, retain) ItemInfo* modifiedItem;

@end
