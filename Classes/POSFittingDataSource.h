//
//  POSFittingDataSource.h
//  EVEUniverse
//
//  Created by mr_depth on 14.08.13.
//
//

#import <Foundation/Foundation.h>

@class POSFittingViewController;
@interface POSFittingDataSource : NSObject<UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, weak) IBOutlet POSFittingViewController *posFittingViewController;
@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic, strong) IBOutlet UIView *tableHeaderView;
- (void) reload;

@end