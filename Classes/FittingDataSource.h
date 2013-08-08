//
//  FittingDataSource.h
//  EVEUniverse
//
//  Created by mr_depth on 06.08.13.
//
//

#import <Foundation/Foundation.h>

@class FittingViewController;
@interface FittingDataSource : NSObject<UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, weak) IBOutlet FittingViewController *fittingViewController;
@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic, strong) IBOutlet UIView *tableHeaderView;
- (void) reload;

@end
