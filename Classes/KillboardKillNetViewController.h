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
@interface KillboardKillNetViewController : UIViewController<UITableViewDataSource, CollapsableTableViewDelegate>
@property (retain, nonatomic) IBOutlet UITableView *tableView;
@property (retain, nonatomic) EVEKillNetLog* killLog;

@end
