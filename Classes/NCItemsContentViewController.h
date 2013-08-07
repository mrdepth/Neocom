//
//  NCItemsContentViewController.h
//  EVEUniverse
//
//  Created by mr_depth on 04.08.13.
//
//

#import <UIKit/UIKit.h>

@class NCItemsViewController;
@interface NCItemsContentViewController : UITableViewController<UISearchBarDelegate, UISearchDisplayDelegate>
@property (nonatomic, weak) NCItemsViewController* itemsViewController;
@end
