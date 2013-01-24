//
//  FittingItemsViewController.h
//  EVEUniverse
//
//  Created by Artem Shimanski on 21.01.13.
//
//

#import <UIKit/UIKit.h>
#import "FittingItemsViewControllerDelegate.h"

@class EVEDBInvGroup;
@class ItemInfo;
@interface FittingItemsViewController : UIViewController<UITableViewDataSource, UITableViewDelegate, UISearchDisplayDelegate, UIPopoverControllerDelegate, FittingItemsViewControllerDelegate>
@property (nonatomic, retain) IBOutlet UITableView *tableView;
@property (nonatomic, assign) IBOutlet UIViewController *mainViewController;
@property (nonatomic, assign) IBOutlet id<FittingItemsViewControllerDelegate> delegate;
@property (nonatomic, assign) NSInteger marketGroupID;
@property (nonatomic, retain) NSArray* except;

@property (nonatomic, retain) NSString *groupsRequest;
@property (nonatomic, retain) NSString *typesRequest;
@property (nonatomic, retain) NSString *searchRequest;
//@property (nonatomic, retain) EVEDBInvGroup *group;
@property (nonatomic, retain) ItemInfo* modifiedItem;

@end
