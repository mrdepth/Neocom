//
//  KillboardKillNetViewController.h
//  EVEUniverse
//
//  Created by Artem Shimanski on 13.11.12.
//
//

#import <UIKit/UIKit.h>
#import "CollapsableTableView.h"

@class EVEKillNetLog;
@interface KillboardKillNetViewController : UITableViewController<CollapsableTableViewDelegate>
@property (strong, nonatomic) EVEKillNetLog* killLog;

@end
