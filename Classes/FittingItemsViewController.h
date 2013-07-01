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
@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic, weak) IBOutlet UIViewController *mainViewController;
@property (nonatomic, weak) IBOutlet id<FittingItemsViewControllerDelegate> delegate;
@property (nonatomic, assign) NSInteger marketGroupID;
@property (nonatomic, strong) NSArray* except;

@property (nonatomic, strong) NSString *groupsRequest;
@property (nonatomic, strong) NSString *typesRequest;
@property (nonatomic, strong) NSString *searchRequest;
@property (nonatomic, strong) ItemInfo* modifiedItem;

@end
